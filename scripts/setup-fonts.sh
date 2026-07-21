#!/bin/bash
# setup-fonts.sh: Apply host font fixes and share them with Flatpak apps.
#
# Usage:
#   ./scripts/setup-fonts.sh fix             # install general host fixes
#   ./scripts/setup-fonts.sh sync            # host fixes + Flatpak sync
#   ./scripts/setup-fonts.sh unfix           # remove general host fixes
#   ./scripts/setup-fonts.sh unsync          # revert Flatpak sync + grants
#   ./scripts/setup-fonts.sh state           # show current state (dry-run)

set -e

GENERAL_FILE_NAME="99-system-ui.conf"
SYNC_FILE_NAME="99-flatpak-host-sync.conf"
SYNC_GRANTS=(host-os host-etc xdg-config/fontconfig ~/.local/share/fonts)

show_usage() {
    cat <<EOF
Usage:
  $0 fix                          Install general host font fixes
  $0 sync                         Install host fixes + Flatpak sync (recommended)
  $0 unfix                        Remove general host font fixes
  $0 unsync                       Revert sync and revoke filesystem grants
  $0 state                        Print current state (overrides, fc-match diff)
  $0 -h | --help                  This help

Examples:
  $0 fix
  $0 sync
  $0 state
  $0 unsync
EOF
}

get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(readlink -f "$0")")"
}

general_fixes_installed() {
    [[ -f "$HOME/.config/fontconfig/conf.d/$GENERAL_FILE_NAME" ]]
}

sync_is_installed() {
    [[ -f "$HOME/.config/fontconfig/conf.d/$SYNC_FILE_NAME" ]]
}

write_conf() {
    local filename="$1"
    local target="$HOME/.config/fontconfig/conf.d/$filename"
    local repo_template="$REPO_ROOT/configs/.config/fontconfig/conf.d/$filename"
    mkdir -p "$(dirname "$target")"

    if cmp -s "$repo_template" "$target" 2>/dev/null; then
        echo "  Already up to date: $target"
    else
        cp "$repo_template" "$target"
        echo "  Wrote: $target"
    fi
}

install_general_logic() {
    echo "=== Installing general font fixes ==="
    write_conf "$GENERAL_FILE_NAME"
    fc-cache -f >/dev/null
    echo "  system-ui Thai: $(fc-match 'system-ui:charset=0E01' 2>/dev/null | sed 's/^[^:]*: //' || true)"
}

uninstall_general_logic() {
    local target="$HOME/.config/fontconfig/conf.d/$GENERAL_FILE_NAME"
    if [[ -f "$target" ]]; then
        rm -f "$target"
        echo "Removed general font fixes: $target"
    else
        echo "General font fixes are not installed."
    fi
    fc-cache -f >/dev/null
}

apply_sync_grants() {
    if ! command -v flatpak &>/dev/null; then
        echo "  Notice: flatpak command not found — skipping Flatpak filesystem overrides."
        return 0
    fi
    local args=()
    for g in "${SYNC_GRANTS[@]}"; do
        args+=(--filesystem="${g}:ro")
    done
    flatpak override --user "${args[@]}"
}

revoke_sync_grants() {
    if ! command -v flatpak &>/dev/null; then
        return 0
    fi
    local args=()
    for g in "${SYNC_GRANTS[@]}"; do
        args+=(--nofilesystem="$g")
    done
    flatpak override --user "${args[@]}"
}

wipe_app_caches() {
    [[ -d "$HOME/.var/app" ]] || return 0
    find "$HOME/.var/app" -maxdepth 4 -type d -name fontconfig -path '*/cache/*' \
        -exec rm -rf {} + 2>/dev/null || true
}

detect_app_for_probe() {
    command -v flatpak &>/dev/null || return 0
    flatpak list --app --columns=application 2>/dev/null \
        | grep -v '^Application$' \
        | head -1
}

verify_sync() {
    local app
    app=$(detect_app_for_probe)
    if [[ -z "$app" ]]; then
        echo "  (no Flatpak apps installed — skipping sandbox probe)"
        return 0
    fi

    local host_match sandbox_match
    host_match=$(fc-match :lang=th 2>/dev/null | sed 's/^[^:]*: //')
    sandbox_match=$(flatpak run --command=fc-match "$app" :lang=th 2>/dev/null | sed 's/^[^:]*: //' || echo "")

    echo "  Host    (lang=th): ${host_match:-?}"
    echo "  Sandbox (lang=th): ${sandbox_match:-(probe failed — app may not have fc-match)}"
    if [[ -n "$sandbox_match" && "$host_match" == "$sandbox_match" ]]; then
        echo "  Result: PASS — sandbox matches host."
    else
        echo "  Result: mismatch (restart running Flatpak apps; new launches should pick up changes)."
    fi
}

install_sync_logic() {
    echo "=== Installing general font fixes + Flatpak sync ==="
    echo ""

    echo "Step 1/5 — Installing general host font fixes..."
    write_conf "$GENERAL_FILE_NAME"

    echo "Step 2/5 — Writing Flatpak sync fontconfig snippet..."
    write_conf "$SYNC_FILE_NAME"

    echo "Step 3/5 — Applying global Flatpak filesystem grants..."
    apply_sync_grants

    echo "Step 4/5 — Refreshing host font cache..."
    fc-cache -f >/dev/null

    echo "Step 5/5 — Verifying sandbox sees host fonts..."
    verify_sync

    echo ""
    echo "Done. Restart any already-running Flatpak apps to pick up the change."
}

unsync_logic() {
    echo "=== Reverting Flatpak host-fontconfig sync ==="
    echo ""

    local target="$HOME/.config/fontconfig/conf.d/$SYNC_FILE_NAME"
    if [[ -f "$target" ]]; then
        rm -f "$target"
        echo "  Removed: $target"
    else
        echo "  (no sync conf file to remove)"
    fi

    echo "  Revoking filesystem grants..."
    revoke_sync_grants

    echo "  Refreshing host font cache..."
    fc-cache -f >/dev/null

    echo "  Wiping per-app fontconfig caches..."
    wipe_app_caches

    echo ""
    echo "Done. Restart any already-running Flatpak apps to pick up the change."
}

show_state() {
    echo "=== Font State ==="
    echo ""

    if sync_is_installed; then
        echo "Flatpak sync: INSTALLED"
    else
        echo "Flatpak sync: not installed"
    fi
    if general_fixes_installed; then
        echo "General font fixes: INSTALLED"
    else
        echo "General font fixes: not installed"
    fi
    echo ""

    if command -v flatpak &>/dev/null; then
        echo "Active Flatpak --user overrides:"
        local raw
        raw=$(flatpak override --user --show 2>/dev/null || true)
        if [[ -z "$raw" ]]; then
            echo "  (none)"
        else
            printf '%s\n' "$raw" | sed 's/^/  /'
        fi
    fi
    echo ""

    echo "Host fc-match (common languages):"
    local lang
    for lang in th ja ko zh-cn ar he hi; do
        printf "  %-6s -> %s\n" "$lang" "$(fc-match :lang=$lang 2>/dev/null | sed 's/^[^:]*: //')"
    done
    echo ""

    local probe_app
    probe_app=$(detect_app_for_probe)
    if [[ -n "$probe_app" ]]; then
        echo "Sandbox probe via $probe_app:"
        for lang in th ja ko; do
            local out
            out=$(flatpak run --command=fc-match "$probe_app" :lang=$lang 2>/dev/null \
                | sed 's/^[^:]*: //' || echo "(probe failed)")
            printf "  %-6s -> %s\n" "$lang" "${out:-(probe failed)}"
        done
    fi
}

# --- Main ---

REPO_ROOT=$(get_repo_root)

case "${1:-}" in
    fix)        install_general_logic ;;
    sync)       install_sync_logic ;;
    unfix)      uninstall_general_logic ;;
    unsync)     unsync_logic ;;
    state)      show_state ;;
    -h|--help)  show_usage ;;
    *)          show_usage; exit 1 ;;
esac
