#!/usr/bin/env python3
"""arch-fortify.py — Persistent CachyOS de-branding.

Usage:
  sudo python3 arch-fortify.py              # Apply changes
  sudo python3 arch-fortify.py -v           # Verbose (stream command output)
  sudo python3 arch-fortify.py --dry        # Preview only
  sudo python3 arch-fortify.py --restore    # Roll back latest backup
  sudo python3 arch-fortify.py --restore 20260509_182622  # Specific backup
  sudo python3 arch-fortify.py --list-backups  # List available backups
  sudo python3 arch-fortify.py --skip hooks,limine  # Skip specific sections
  sudo python3 arch-fortify.py --plymouth-theme bgrt  # Customize theme
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

__version__ = "2.3.0"

BACKUP_ROOT = Path("/var/lib/arch-fortify/backups")

LIMINE_CONF = Path("/boot/limine.conf")
CACHYOS_ENTRY = "/+CachyOS"
ARCH_ENTRY = "/+Arch Linux"

DRY_RUN = False
VERBOSE = False
HAD_ERRORS = False
SKIP_SECTIONS = set()
PLYMOUTH_THEME = "bgrt"

MAX_BACKUPS = 10


def prune_backups(keep: int | None = None):
    """Remove old backup directories beyond the retention count."""
    limit = keep if keep is not None else MAX_BACKUPS
    if not BACKUP_ROOT.exists():
        return
    dirs = sorted([d for d in BACKUP_ROOT.iterdir() if d.is_dir()])
    if len(dirs) <= limit:
        return
    for d in dirs[:-limit]:
        try:
            shutil.rmtree(d)
            info(f"Pruned old backup: {d.name}")
        except Exception as e:
            warn(f"Failed to prune backup {d.name}: {e}")


# ── Utilities ─────────────────────────────────────────────────────────


def _color(code: str, text: str) -> str:
    if hasattr(sys.stdout, "isatty") and sys.stdout.isatty():
        return f"{code}{text}\033[0m"
    return text


def info(msg):
    print(f"  {_color('\033[34;1m', 'INFO')}  {msg}")


def ok(msg):
    print(f"  {_color('\033[32;1m', ' OK ')}  {msg}")


def warn(msg):
    print(f"  {_color('\033[33;1m', 'WARN')}  {msg}")


def fail(msg):
    print(f"  {_color('\033[31;1m', 'FAIL')}  {msg}")
    sys.exit(1)


def err(msg):
    global HAD_ERRORS
    HAD_ERRORS = True
    print(f"  {_color('\033[31;1m', 'ERR ')}  {msg}")


def safe_symlink(target: str, link: str):
    link_p = Path(link)
    target_p = Path(target)
    if link_p.is_symlink() and link_p.readlink() == target_p:
        ok(f"Symlink {link} already correct")
        return
    if DRY_RUN:
        info(f"Would symlink {link} -> {target}")
        return
    link_p.unlink(missing_ok=True)
    link_p.symlink_to(target_p)
    ok(f"Symlinked {link} -> {target}")


def run(args, check=True, optional=False):
    """Run a command.  If *optional*, warn on missing binary instead of failing."""
    if DRY_RUN:
        info(f"Would run: {' '.join(args)}")
        return None
    try:
        if VERBOSE:
            info(f"Running: {' '.join(args)}")
            return subprocess.run(args, check=check)
        result = subprocess.run(args, check=check, capture_output=True, text=True)
        out = result.stdout.strip()
        if out:
            print(f"  {out}")
        return result
    except FileNotFoundError:
        msg = f"Binary '{args[0]}' not found, skipping."
        if optional:
            warn(msg)
            return None
        fail(msg)
    except subprocess.CalledProcessError as e:
        if not VERBOSE:
            print(f"  stderr: {e.stderr.strip()}")
        if check:
            sys.exit(1)
        return e


def safe_write(path: Path, content: str, desc: str = ""):
    """Write *content* to *path*, fsyncing before rename for crash safety on FAT32/ESP."""
    if DRY_RUN:
        info(f"Would write {path}" + (f"  ({desc})" if desc else ""))
        return
    tmp = path.with_suffix(".tmp")
    with open(tmp, "w") as fh:
        fh.write(content)
        fh.flush()
        os.fsync(fh.fileno())
    tmp.rename(path)
    ok(f"Wrote {path}" + (f"  ({desc})" if desc else ""))


# ── Backup / Restore ──────────────────────────────────────────────────


def backup_file(path: Path, backup_dir: Path) -> Path | None:
    """Copy *path* into the backup directory, mirroring its directory structure."""
    if not path.exists():
        return None
    dst = backup_dir / path.relative_to("/")
    if DRY_RUN:
        info(f"Would backup {path} -> {dst}")
        return dst
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dst)
    info(f"Backed up {path}")
    return dst


def list_backups():
    """List all available backups with timestamps and file counts."""
    if not BACKUP_ROOT.exists():
        print("No backups found.")
        return

    dirs = sorted([d for d in BACKUP_ROOT.iterdir() if d.is_dir()])
    if not dirs:
        print("No backups found.")
        return

    print("\nAvailable backups:")
    for bak_dir in reversed(dirs):
        file_count = sum(1 for p in bak_dir.rglob("*") if p.is_file())
        print(f"  {bak_dir.name}  ({file_count} files)")


def restore_backup(timestamp: str | None = None):
    """Restore the most recent (or specified) backup."""
    if timestamp:
        src_dir = BACKUP_ROOT / timestamp
    else:
        dirs = sorted([d for d in BACKUP_ROOT.iterdir() if d.is_dir()])
        if not dirs:
            fail("No backups found.")
        src_dir = dirs[-1]
    if not src_dir.is_dir():
        fail(f"Backup directory {src_dir} not found.")

    for path in sorted(src_dir.rglob("*")):
        if not path.is_file():
            continue
        dest = Path("/") / path.relative_to(src_dir)
        if DRY_RUN:
            info(f"Would restore {path} -> {dest}")
            continue
        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, dest)
            ok(f"Restored {dest}")
        except Exception as e:
            err(f"Failed to restore {dest}: {e}")
    run(["limine-update"], optional=True)


# ── 1. Identity Guard ─────────────────────────────────────────────────


def mask_branding_hooks():
    print("\n── 1. Identity Guard ──")
    hook_dir = Path("/usr/share/libalpm/hooks/")
    target_dir = Path("/etc/libalpm/hooks/")

    if not hook_dir.is_dir():
        info("No hooks directory, skipping.")
        return

    if not DRY_RUN:
        target_dir.mkdir(parents=True, exist_ok=True)
    found = False

    for hook in sorted(hook_dir.glob("*.hook")):
        content = hook.read_text()
        # Only consider hooks from CachyOS that modify identity or run branding
        if "cachyos" not in content.lower():
            continue

        # Detect: hooks that target identity packages or execute branding operations
        targets_identity = any(
            pkg in content
            for pkg in [
                "os-release",
                "lsb-release",
                "issue",
                "filesystem",
                "cachyos-branding",
            ]
        )
        # Also check for hooks that explicitly run branding commands
        runs_branding = bool(
            re.search(r"Exec\s*=.*(?:branding|cachyos)", content, re.IGNORECASE)
        )

        if not (targets_identity or runs_branding):
            continue

        found = True
        safe_symlink("/dev/null", str(target_dir / hook.name))

    if not found:
        ok("No CachyOS branding hooks detected.")

    # Clean up orphaned masks (hook was removed upstream)
    for mask in sorted(target_dir.glob("*.hook")):
        if not (hook_dir / mask.name).exists():
            if DRY_RUN:
                info(f"Would remove orphaned mask: {mask}")
            else:
                mask.unlink()
                ok(f"Removed orphaned mask: {mask.name}")


# ── 2. Identity Restoration ──────────────────────────────────────────


def restore_identity(backup_dir: Path):
    print("\n── 2. Identity Restoration ──")

    backup_file(Path("/etc/os-release"), backup_dir)
    backup_file(Path("/etc/lsb-release"), backup_dir)
    backup_file(Path("/etc/issue"), backup_dir)

    run(["pacman", "-S", "--noconfirm", "--needed", "filesystem", "lsb-release"])

    for name in ("os-release", "lsb-release"):
        safe_symlink(f"/usr/lib/{name}", f"/etc/{name}")

    # Restore /etc/issue (also trampled by cachyos-branding)
    etc_issue = Path("/etc/issue")
    if etc_issue.exists():
        content = etc_issue.read_text()
        # Replace any "CachyOS" remnants with the Arch default template
        cleaned = content.replace("CachyOS Linux", "\\S{PRETTY_NAME}")
        cleaned = cleaned.replace("CachyOS", "\\S{PRETTY_NAME}")
        if cleaned != content:
            safe_write(etc_issue, cleaned, desc="purged CachyOS from /etc/issue")
        else:
            ok("/etc/issue already clean")
    else:
        # Re-create from the factory default
        factory = Path("/usr/share/factory/etc/issue")
        if factory.exists():
            safe_write(
                etc_issue, factory.read_text(), desc="restored from factory default"
            )

    # Same for the factory copy
    factory_issue = Path("/usr/share/factory/etc/issue")
    if factory_issue.exists():
        content = factory_issue.read_text()
        cleaned = content.replace("CachyOS Linux", "\\S{PRETTY_NAME}")
        cleaned = cleaned.replace("CachyOS", "\\S{PRETTY_NAME}")
        if cleaned != content:
            safe_write(
                factory_issue, cleaned, desc="purged CachyOS from factory /etc/issue"
            )

    # Verify
    if not DRY_RUN:
        for line in Path("/etc/os-release").read_text().splitlines():
            if line.startswith("NAME="):
                ok(f"/etc/os-release says: {line}")


# ── 3. Display Managers ─────────────────────────────────────────────


def fix_display_managers(backup_dir: Path):
    print("\n── 3. Display Managers ──")

    has_gdm = shutil.which("gdm")
    has_sddm = shutil.which("sddm")

    if not has_gdm and not has_sddm:
        info("No supported display manager detected (GDM or SDDM).")
        return

    # ── GDM ──
    if has_gdm:
        if not shutil.which("glib-compile-schemas"):
            warn("glib-compile-schemas not found, skipping GDM step.")
        else:
            override = Path(
                "/usr/share/glib-2.0/schemas/zzzz_arch-fix.gschema.override"
            )
            content = "[org.gnome.login-screen]\nlogo=''\n"
            if override.exists() and override.read_text() == content:
                ok("GDM schema override already correct.")
            else:
                backup_file(override, backup_dir)
                safe_write(override, content, desc="GDM logo schema override")
                run(["glib-compile-schemas", "/usr/share/glib-2.0/schemas/"])
                ok("GDM schema override installed.")

    # ── SDDM ──
    if has_sddm:
        sddm_conf_d = Path("/etc/sddm.conf.d")
        if not DRY_RUN:
            sddm_conf_d.mkdir(parents=True, exist_ok=True)
        sddm_override = sddm_conf_d / "01-arch-fortify.conf"
        content = "[Theme]\nCurrent=elarun\n"

        if sddm_override.exists() and sddm_override.read_text() == content:
            ok("SDDM theme override already correct (elarun).")
        else:
            backup_file(sddm_override, backup_dir)
            safe_write(sddm_override, content, desc="SDDM theme reset to stock elarun")
            ok("SDDM theme override installed.")


# ── 4. Limine ────────────────────────────────────────────────────────


def _detect_indent(lines: list[str], default: int = 5) -> int:
    for ln in lines:
        if ln.strip():
            return len(ln) - len(ln.lstrip())
    return default


def _validate_limine(final_content: str, entry_count: int) -> bool:
    """Sanity-check composed limine.conf content before writing.

    Returns False to block the write when a critical problem is detected.
    """
    ok_to_write = True

    if ARCH_ENTRY not in final_content:
        if CACHYOS_ENTRY in final_content:
            warn(
                f"  LIMINE: {CACHYOS_ENTRY!r} present but no {ARCH_ENTRY!r} — run identity step first."
            )
        else:
            err(
                f"  LIMINE: No {ARCH_ENTRY!r} entry in composed config — refusing to write (would be unbootable)."
            )
            ok_to_write = False
    elif CACHYOS_ENTRY in final_content:
        warn(f"  LIMINE: stale {CACHYOS_ENTRY!r} still present after scrubbing.")

    m = re.search(r"^default_entry:\s*(\d+)", final_content, re.MULTILINE)
    if not m:
        warn(
            "  LIMINE: default_entry not found — Limine will use its internal default."
        )
    elif entry_count > 0:
        entry_no = int(m.group(1))
        if entry_no > entry_count:
            warn(
                f"  LIMINE: default_entry ({entry_no}) > entry count ({entry_count}) — check dual-boot setup."
            )
        else:
            ok(f"  LIMINE: default_entry = {entry_no} (valid, {entry_count} entries).")

    return ok_to_write


def clean_limine(backup_dir: Path):
    print("\n── 4. Limine ──")

    if not Path("/boot").is_mount():
        warn("/boot is not mounted — skipping Limine operations.")
        return

    conf = LIMINE_CONF
    if not conf.exists():
        info(f"{conf} not found, skipping.")
        return

    backup_file(conf, backup_dir)
    content = conf.read_text()

    # ── Phase A: Boot entry regeneration ──────────────────────────
    # If CachyOS boot entry exists, run tools to capture snapshots and
    # regenerate a proper Arch Linux entry (tools read os-release which
    # was already restored in step 2). The state machine below strips
    # any stale /+CachyOS that remains.
    _regenerated = False
    if CACHYOS_ENTRY in content:
        info(f"{CACHYOS_ENTRY!r} entry found. Snapshot sync + boot regeneration...")
        if not DRY_RUN:
            run(["limine-update"], optional=True)
            run(["limine-snapper-sync"], optional=True)
            content = conf.read_text()
            _regenerated = True

    # ── Strip CachyOS theme block ────────────────────────────────
    # 1) Full block when comment header exists
    stripped = re.sub(
        r"^# CachyOS Limine theme[^\n]*\n(?:[^\n]+\n)*",
        "",
        content,
        flags=re.MULTILINE,
    )
    # 2) Orphan wallpaper pointing to CachyOS splash (survives header removal)
    stripped = re.sub(
        r"^wallpaper:\s*boot\(\):/limine-splash\.png\s*\n?",
        "",
        stripped,
        flags=re.MULTILINE,
    )
    # 3) Orphan empty interface_branding (CachyOS default; non-empty left alone)
    stripped = re.sub(
        r"^interface_branding:\s*$\n?",
        "",
        stripped,
        flags=re.MULTILINE,
    )
    if stripped != content:
        content = stripped
    # Collapse multiple blank lines into one
    content = re.sub(r"\n{3,}", "\n\n", content)

    lines = content.splitlines(keepends=True)

    # ── Multi-scenario state machine ──────────────────────────────
    # Clean install:    header → /+Arch Linux → //kernels → //Snapshots → /+Windows → /EFI
    # Orphan recovery:  header → //Snapshots → /+Arch Linux → /EFI
    # Already clean:    header → /+Arch Linux → /EFI
    # Dual-boot:        ... → /+Windows → /EFI

    hs, sk, sn, ar, oe, ef = [], [], [], [], [], []
    state = "header"

    def flush_skipping():
        while hs and not hs[-1].strip():
            hs.pop()
        # Only pop a genuine `comment: …` key line, not arbitrary lines containing "comment:"
        if hs and re.match(r"\s*comment:", hs[-1]):
            hs.pop()
        while hs and not hs[-1].strip():
            hs.pop()

    for line in lines:
        s = line.strip()

        # ── State transitions ─────────────────────────────────────
        # Priority: EFI terminates all → Arch always recognized →
        # CachyOS caught from any state → per-state exits.
        if s.startswith("/EFI") or s.startswith("//EFI"):
            state = "efi"
        elif s.startswith(ARCH_ENTRY):
            state = "arch_linux"
        elif s.startswith(CACHYOS_ENTRY):
            if state == "header":
                flush_skipping()
            state = "skip_cachyos"
            continue
        elif state in ("arch_linux", "other") and s.startswith("/+"):
            state = "other"  # dual-boot entry like /+Windows
        elif state == "snapshots" and s.startswith("/+"):
            state = "other"  # exit snapshots on the next top-level entry
        elif state in ("header", "skip_cachyos") and s.startswith("//Snapshots"):
            state = "snapshots"
        elif state == "skip_cachyos" and s.startswith("/+"):
            state = "arch_linux"  # orphan-recovery: first /+ after CachyOS block

        # ── Append ────────────────────────────────────────────────
        if state == "header":
            hs.append(line)
        elif state == "skip_cachyos":
            sk.append(line)
        elif state == "snapshots":
            sn.append(line)
        elif state == "arch_linux":
            ar.append(line)
        elif state == "other":
            oe.append(line)
        elif state == "efi":
            ef.append(line)

    if DRY_RUN:
        print(f"  header:       {len(hs)} lines")
        print(f"  skip/kernels: {len(sk)} lines (stale CachyOS → removed)")
        print(f"  snapshots:    {len(sn)} lines (will be moved inside Arch Linux)")
        print(f"  arch_linux:   {len(ar)} lines")
        print(f"  other_entries:{len(oe)} lines (dual-boot etc. — preserved)")
        print(f"  efi/other:    {len(ef)} lines")

    # ── Post-process `ar`: remove duplicate //Arch Linux sections ──
    # limine-snapper-sync may have created one underneath the current
    # entry when the OS name changed.  We keep //Snapshots instead.
    filtered_ar = []
    skip_dup = False
    for ln in ar:
        s = ln.strip()
        if s == "//Arch Linux":
            skip_dup = True
            continue
        if skip_dup:
            if (
                s.startswith("//Snapshots")
                or s.startswith("/+")
                or s.startswith("//EFI")
                or s.startswith("/EFI")
            ):
                skip_dup = False
                filtered_ar.append(ln)  # always preserve the terminator line
            continue  # skip orphan content (terminator already appended above)
        filtered_ar.append(ln)
    ar = filtered_ar

    # ── Re-indent orphaned snapshots for nesting under /+Arch Linux ──
    if sn:
        if not ar:
            warn(
                "Snapshots section found but no /+Arch Linux entry — snapshots may be unnested in output."
            )
        base_indent = _detect_indent(sn, 5)
        reindented = []
        for ln in sn:
            if ln.strip():
                cur = len(ln) - len(ln.lstrip())
                rel = cur - base_indent
                reindented.append(" " * max(0, 2 + rel) + ln.lstrip())
            else:
                reindented.append("\n")

        # Insert after the last kernel line
        insert_at = len(ar)
        for i in range(len(ar) - 1, -1, -1):
            t = ar[i].strip()
            if t.startswith("//") and not t.startswith("//+"):
                insert_at = i + 1
                break
        while insert_at < len(ar) and not ar[-1].strip():
            ar.pop()

        ar = ar[:insert_at] + ["\n"] + reindented + ["\n"] + ar[insert_at:]

    # ── Post-process `oe`: strip orphaned kernel-entry fragments ──
    oe_clean = []
    in_orphan = False
    for ln in oe:
        s = ln.strip()
        # Start of an orphaned kernel fragment (indented, auto-gen comment)
        if (ln.startswith(" ") and "### This kernel entry" in s) or (
            ln.startswith(" ") and "protocol: linux" in s
        ):
            in_orphan = True
        if in_orphan:
            # End: blank line or next section header
            if (
                not s
                or s.startswith("/+")
                or s.startswith("/EFI")
                or s.startswith("//EFI")
            ):
                in_orphan = False
                if s:
                    oe_clean.append(ln)
                continue
            continue  # skip orphan content
        oe_clean.append(ln)
    oe = oe_clean

    # ── Compose output ────────────────────────────────────────────
    out_lines = hs + ["\n"] + ar + oe + ef

    if DRY_RUN:
        info("Would write updated /boot/limine.conf")
        print(f"    Lines before: {len(lines)}  after: {len(out_lines)}")
        return

    # ── Update default_entry in-memory ───────────────────────────
    # Count entries and locate Arch Linux — done once here, not re-derived in validator.
    entry_count = 0
    arch_no = None
    for ln in out_lines:
        if ln.strip().startswith("/+"):
            entry_count += 1
            if ARCH_ENTRY in ln:
                arch_no = entry_count

    final_content = "".join(out_lines)
    if arch_no is not None:
        updated = re.sub(
            r"^default_entry:\s*\d+.*",
            f"default_entry: {arch_no}",
            final_content,
            flags=re.MULTILINE,
        )
        if updated != final_content:
            final_content = updated
        else:
            ok("default_entry already points to Arch Linux.")
    else:
        warn("Could not determine Arch Linux entry number — default_entry left as-is.")

    # ── Validate before write ─────────────────────────────────────
    if not _validate_limine(final_content, entry_count):
        err("limine.conf NOT written — validation blocked the write.")
        return

    # ── Single atomic write ───────────────────────────────────────
    safe_write(conf, final_content, desc="limine.conf (scrubbed + default_entry)")

    # ── Regenerate (skipped if already done in the rename branch) ─
    if not _regenerated:
        run(["limine-mkinitcpio"], optional=True)
        run(["limine-update"], optional=True)
    ok("Boot menu regenerated.")


# ── 5. Plymouth ──────────────────────────────────────────────────────


def restore_plymouth(backup_dir: Path):
    print("\n── 5. Plymouth ──")
    if not shutil.which("plymouth-set-default-theme"):
        info("plymouth not installed, skipping.")
        return

    # Check current theme via the official tool (more reliable than grepping config)
    try:
        out = subprocess.run(
            ["plymouth-set-default-theme"],
            capture_output=True,
            text=True,
            check=False,
        ).stdout.strip()
    except Exception:
        out = ""

    if out == PLYMOUTH_THEME:
        ok(f"Plymouth already set to {PLYMOUTH_THEME}.")
        return

    if DRY_RUN:
        info(f"Would run: plymouth-set-default-theme {PLYMOUTH_THEME} && mkinitcpio -P")
        return

    backup_file(Path("/etc/plymouth/plymouthd.conf"), backup_dir)
    result = run(["plymouth-set-default-theme", PLYMOUTH_THEME], check=False)
    if result and result.returncode != 0:
        err(f"Failed to set Plymouth theme to {PLYMOUTH_THEME}")
        return
    run(["mkinitcpio", "-P"])
    ok(f"Plymouth theme set to {PLYMOUTH_THEME}.")


# ── 6. Verify ────────────────────────────────────────────────────────


def verify():
    print("\n── 6. Verification ──")
    if DRY_RUN:
        info("Dry run — no changes applied.")
        return

    # OS identity
    for line in Path("/etc/os-release").read_text().splitlines():
        if line.startswith(("NAME=", "PRETTY_NAME=")):
            print(f"  {line}")

    # Hook masks
    hook_dir = Path("/etc/libalpm/hooks/")
    masked = sorted(hook_dir.glob("*.hook")) if hook_dir.exists() else []
    if masked:
        for m in masked:
            if m.is_symlink() and m.readlink() == Path("/dev/null"):
                print(f"  HOOK: {m.name} → masked")
    else:
        print("  HOOK: none masked (all clean, no branding hooks found)")

    # Limine
    if LIMINE_CONF.exists():
        content = LIMINE_CONF.read_text()
        if CACHYOS_ENTRY in content:
            warn(f"  LIMINE: stale {CACHYOS_ENTRY!r} entry still present!")
        else:
            ok("  LIMINE: no stale CachyOS entries.")
        if "//Snapshots" in content:
            ok("  LIMINE: snapshots section present.")

    # Scan /etc/ for any remaining "CachyOS" strings in UI-relevant files
    ui_files = [
        "/etc/os-release",
        "/etc/lsb-release",
        "/etc/issue",
    ]
    cachyos_found = False
    for f in ui_files:
        p = Path(f)
        if p.exists() and "CachyOS" in p.read_text():
            warn(f"  REMAINING: 'CachyOS' found in {f}")
            cachyos_found = True
    if not cachyos_found:
        ok("  No CachyOS branding found in identity files.")

    # Display managers
    gdm_override = Path("/usr/share/glib-2.0/schemas/zzzz_arch-fix.gschema.override")
    if gdm_override.exists():
        ok("  GDM: schema override in place (logo cleared).")

    sddm_override = Path("/etc/sddm.conf.d/01-arch-fortify.conf")
    if sddm_override.exists():
        ok("  SDDM: theme override in place (elarun).")

    # Report any accumulated errors
    if HAD_ERRORS:
        warn("Some steps had errors — review the output above.")


# ── Main ─────────────────────────────────────────────────────────────


def main():
    global DRY_RUN, VERBOSE, SKIP_SECTIONS, PLYMOUTH_THEME

    parser = argparse.ArgumentParser(
        description="Persistent CachyOS de-branding for Arch Linux",
        epilog="Examples:\n"
        "  sudo arch-fortify.py              # Apply de-branding\n"
        "  sudo arch-fortify.py --dry        # Preview changes\n"
        "  sudo arch-fortify.py --restore    # Restore latest backup\n"
        "  sudo arch-fortify.py --skip limine  # Skip Limine section\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--version", "-V", action="version", version=f"%(prog)s {__version__}"
    )
    parser.add_argument(
        "--dry", action="store_true", help="Preview changes without writing"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Stream command output"
    )
    parser.add_argument(
        "--restore",
        nargs="?",
        const=None,
        metavar="TIMESTAMP",
        help="Restore backup (latest if no timestamp given)",
    )
    parser.add_argument(
        "--list-backups", action="store_true", help="List available backups"
    )
    parser.add_argument(
        "--skip",
        metavar="SECTIONS",
        help="Skip comma-separated sections (hooks,identity,display-managers,limine,plymouth); 'gdm' accepted as alias",
    )
    parser.add_argument(
        "--plymouth-theme",
        default="bgrt",
        metavar="THEME",
        help="Plymouth theme to restore (default: bgrt)",
    )

    args = parser.parse_args()

    if args.list_backups:
        list_backups()
        return 0

    if args.restore is not None:
        if not os.geteuid() == 0:
            fail("Must run as root (sudo).")
        restore_backup(args.restore)
        return 0 if not HAD_ERRORS else 1

    DRY_RUN = args.dry
    VERBOSE = args.verbose
    PLYMOUTH_THEME = args.plymouth_theme

    if args.skip:
        sections = set(s.strip().lower() for s in args.skip.split(","))
        if "gdm" in sections:
            sections.discard("gdm")
            sections.add("display-managers")
        SKIP_SECTIONS = sections

    if DRY_RUN:
        print("═══ DRY RUN — no changes will be written ═══\n")

    if not DRY_RUN and os.geteuid() != 0:
        fail("Must run as root (sudo).")

    backup_dir = BACKUP_ROOT / f"{datetime.now():%Y%m%d_%H%M%S}"

    if not DRY_RUN:
        backup_dir.mkdir(parents=True, exist_ok=True)
        prune_backups()

    if "hooks" not in SKIP_SECTIONS:
        mask_branding_hooks()
    if "identity" not in SKIP_SECTIONS:
        restore_identity(backup_dir)
    if "display-managers" not in SKIP_SECTIONS:
        fix_display_managers(backup_dir)
    if "limine" not in SKIP_SECTIONS:
        clean_limine(backup_dir)
    if "plymouth" not in SKIP_SECTIONS:
        restore_plymouth(backup_dir)
    verify()

    print()
    if DRY_RUN:
        print("═══ Dry run complete. Run without --dry to apply. ═══")
    else:
        ok("De-branding complete. Your system is now persistently Arch Linux.")
        warn("A reboot is recommended to see all changes take effect.")

    return 1 if HAD_ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
