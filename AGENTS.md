# AGENTS.md — system_config

Personal config & documentation for **Lenovo Yoga 7 14AKP10** (Ryzen AI 7 350, Arch Linux/CachyOS).

## Hardware

| Component | Model |
|-----------|-------|
| CPU | AMD Ryzen AI 7 350 (8C/16T, Zen 5 Strix Point, 5.09 GHz boost, 16 MB L3) |
| GPU | AMD Radeon 860M Graphics (integrated, RDNA 3.5) |
| RAM | 32 GB LPDDR5X (soldered, ~30.5 GiB usable) |
| Disk | Samsung PM9C1a 1 TB NVMe (MZAL81T0HFLB-00BL2, DRAM-less) |
| WiFi/BT | Realtek RTL8922AE (rtw89_8922ae driver, 802.11be) |
| Audio DSP | AMD ACP (Audio Coprocessor) + Realtek ALC287 (4-speaker, ALC3306-like layout) |
| Ext Audio | TP35 Pro USB DAC (card 0) |
| Camera | Chicony 04f2:b83c (Integrated) |
| SD Reader | O2 Micro OZ711 |
| Battery | L24D4PK5 (70 Wh design) |
| Boot | Limine |
| Kernel | 7.0.5-2-cachyos, PREEMPT_DYNAMIC |

## Repo layout

| Path | Purpose |
|------|---------|
| `docs/` | How-tos for this laptop model |
| `configs/` | Copy into destination: `sudo cp -r configs/system/* /etc/` |
| `scripts/` | Utility scripts (run from repo root) |

## Scripts

- **`scripts/arch-fortify.py`** — De-brand CachyOS → Arch Linux. Requires Python 3.9+, must run as root (`sudo`).
  - `sudo ./scripts/arch-fortify.py` — apply
  - `sudo ./scripts/arch-fortify.py --dry` — preview
  - `sudo ./scripts/arch-fortify.py --restore` — roll back latest backup
  - `sudo ./scripts/arch-fortify.py --skip hooks,limine` — skip specific sections
  - Backups stored at `/var/lib/arch-fortify/backups/`. Max 10 kept.
  - Limine boot config is rewritten via a state machine; validation checks before write prevent unbootable config.
- **`scripts/setup-flatpak-fonts.sh`** — Flatpak host font sync.
  - `./scripts/setup-flatpak-fonts.sh sync` — recommended mode (host fontconfig inheritance)
  - `./scripts/setup-flatpak-fonts.sh state` — show current sync status
  - `./scripts/setup-flatpak-fonts.sh unsync` — revert
  - `./scripts/setup-flatpak-fonts.sh` (no args) — interactive menu
  - Requires: `git`, `flatpak`, `fc-cache`

## Configs

- **`configs/system/scheduler/scx_loader.toml`** — sched-ext profiles tuned for Strix Point (P-core/E-core topology, shared 16 MB L3 CCX). Default: `scx_lavd` + Powersave mode.
- **`configs/system/network/disable-wifi-powersave.conf`** — WiFi power-save off for RTL892AE.
- **`configs/fontconfig/conf.d/`** — Thai font aliasing + Flatpak host font sync snippet.
- **`configs/system/etc/keyd/default.conf`** — Copilot key chord remap (`Meta+Shift+F23` → F24).
- **`configs/audio/`** — EasyEffects presets for Yoga 7 (4-speaker ALC3306), custom Dolby Atmos impulse responses, PEQ filters.
- **`docs/`** — AUDIO_TUNING, COPILOT_KEY, DEBRANDING, INSTALL_GUIDE, LIMINE_THEMING, TRANSFORM_TO_ARCH.

## Agent workflow notes

- This is a **system config repo**, not a software project. No build/test/lint framework.
- `.opencode/` is gitignored; contains OpenCode plugin deps and archived plans.
- Scripts assume they are run from the repo root (they resolve their own path via git or `readlink`).
- `configs/` files are copied verbatim — they *are* the source of truth, not symlinks.
- Limine config management is complex: the script parses a multi-state boot entry layout, re-indents snapshots, and validates before writing. Do not hand-edit `/boot/limine.conf` directly.
