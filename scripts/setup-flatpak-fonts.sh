#!/bin/bash
# setup-flatpak-fonts.sh: Apply host font fixes and share them with Flatpak apps.
#
# Primary mode:
#   ./scripts/setup-flatpak-fonts.sh                 # interactive menu
#   ./scripts/setup-flatpak-fonts.sh fix             # install general host fixes
#   ./scripts/setup-flatpak-fonts.sh sync            # host fixes + Flatpak sync
#   ./scripts/setup-flatpak-fonts.sh unfix           # remove general host fixes
#   ./scripts/setup-flatpak-fonts.sh unsync          # revert Flatpak sync + grants
#   ./scripts/setup-flatpak-fonts.sh state           # show current state (dry-run)
#   ./scripts/setup-flatpak-fonts.sh list            # list font config status
#
# Legacy mode (force a specific font for one language):
#   ./scripts/setup-flatpak-fonts.sh <lang> <font> [all]
#   ./scripts/setup-flatpak-fonts.sh uninstall [<lang>]

set -e

# --- Functions ---

check_dependencies() {
    for cmd in git flatpak fc-cache; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed. Please install it and try again."
            exit 1
        fi
    done
}

show_usage() {
    cat <<EOF
Usage:
  $0                              Interactive menu
  $0 fix                          Install general host font fixes
  $0 sync                         Install host fixes + Flatpak sync (recommended)
  $0 unfix                        Remove general host font fixes
  $0 unsync                       Revert sync and revoke filesystem grants
  $0 state                        Print current state (overrides, fc-match diff)
  $0 list                         List font config status and legacy configs
  $0 uninstall [<lang>]           Remove a legacy per-language config
  $0 <lang> <font> [all]          Legacy: force a specific font for <lang>
  $0 -h | --help                  This help

Examples:
  $0 fix
  $0 sync
  $0 state
  $0 th "Noto Sans Thai" all      # legacy mode, only if sync isn't enough
  $0 unsync
EOF
}

get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(readlink -f "$0")")"
}

run_interactive_install() {
    echo "=== Flatpak Font Setup Wizard ==="
    echo ""

    declare -A common_langs=(
        ["ar"]="Arabic"
        ["bn"]="Bengali"
        ["zh-cn"]="Chinese (Simplified)"
        ["zh-tw"]="Chinese (Traditional)"
        ["en"]="English"
        ["fr"]="French"
        ["de"]="German"
        ["gu"]="Gujarati"
        ["he"]="Hebrew"
        ["hi"]="Hindi"
        ["ja"]="Japanese"
        ["ko"]="Korean"
        ["ml"]="Malayalam"
        ["mr"]="Marathi"
        ["nb"]="Norwegian"
        ["pa"]="Punjabi"
        ["pt"]="Portuguese"
        ["ru"]="Russian"
        ["sa"]="Sanskrit"
        ["es"]="Spanish"
        ["sv"]="Swedish"
        ["ta"]="Tamil"
        ["te"]="Telugu"
        ["th"]="Thai"
        ["uk"]="Ukrainian"
        ["vi"]="Vietnamese"
    )

    # --- Step 1: Language ---
    echo "Step 1/3 — Select a language:"
    echo ""

    # Build sorted display and key arrays (sort by language name)
    local lang_display=() lang_keys=()
    while IFS=$'\t' read -r _name _code; do
        lang_display+=("$_name ($_code)")
        lang_keys+=("$_code")
    done < <(for _code in "${!common_langs[@]}"; do
        printf '%s\t%s\n' "${common_langs[$_code]}" "$_code"
    done | sort)
    lang_display+=("Other (enter manually)")

    PS3=$'\nChoice: '
    select _choice in "${lang_display[@]}"; do
        if [[ "$_choice" == "Other (enter manually)" ]]; then
            while true; do
                read -rp "  Language code (e.g. ja, ko, zh-cn): " LANG_CODE
                LANG_CODE="${LANG_CODE// /}"
                if [[ $LANG_CODE =~ ^[a-z]{2,3}(-[a-zA-Z]{2,4})?$ ]]; then
                    break
                fi
                echo "  Invalid format. Use 2-3 lowercase letters, optionally '-XX' (e.g. zh-cn)."
            done
            break
        elif [[ -n "$_choice" && "$REPLY" =~ ^[0-9]+$ ]]; then
            local _idx=$(( REPLY - 1 ))
            if [[ $_idx -ge 0 && $_idx -lt ${#lang_keys[@]} ]]; then
                LANG_CODE="${lang_keys[$_idx]}"
                break
            fi
        fi
        echo "  Please enter a number from 1 to ${#lang_display[@]}."
    done
    unset PS3
    echo ""

    # --- Step 2: Font ---
    echo "Step 2/3 — Select a font for '$LANG_CODE'..."
    local raw_fonts
    raw_fonts=$(fc-list ":lang=$LANG_CODE" family 2>/dev/null \
        | tr ',' '\n' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
        | sort -u)

    if [[ -z "$raw_fonts" ]]; then
        echo ""
        echo "Error: No installed fonts support language '$LANG_CODE'."
        echo "Install an appropriate font and re-run the wizard."
        exit 1
    fi

    local font_array=()
    while IFS= read -r _line; do
        [[ -n "$_line" ]] && font_array+=("$_line")
    done <<< "$raw_fonts"

    local font_count=${#font_array[@]}
    echo "Found $font_count font(s)."
    echo ""

    # Offer a filter when the list is long
    local display_fonts=("${font_array[@]}")
    if [[ $font_count -gt 15 ]]; then
        read -rp "  Filter by name (Enter to list all $font_count): " _filter
        if [[ -n "$_filter" ]]; then
            local _matched=()
            for _f in "${font_array[@]}"; do
                [[ "${_f,,}" == *"${_filter,,}"* ]] && _matched+=("$_f")
            done
            if [[ ${#_matched[@]} -eq 0 ]]; then
                echo "  No match for '$_filter' — showing all fonts."
            else
                echo "  ${#_matched[@]} font(s) match."
                display_fonts=("${_matched[@]}")
            fi
        fi
        echo ""
    fi

    if [[ ${#display_fonts[@]} -eq 1 ]]; then
        FONT_FAMILY="${display_fonts[0]}"
        echo "Auto-selected the only available font: $FONT_FAMILY"
    else
        display_fonts+=("Enter name manually...")
        PS3=$'\nChoice: '
        select _choice in "${display_fonts[@]}"; do
            if [[ "$_choice" == "Enter name manually..." ]]; then
                while true; do
                    read -rp "  Font family name (as shown by fc-list): " FONT_FAMILY
                    FONT_FAMILY="$(printf '%s' "$FONT_FAMILY" | xargs)"
                    [[ -n "$FONT_FAMILY" ]] && break
                    echo "  Font name cannot be empty."
                done
                break
            elif [[ -n "$_choice" ]]; then
                FONT_FAMILY="$_choice"
                break
            else
                echo "  Please enter a number from 1 to ${#display_fonts[@]}."
            fi
        done
        unset PS3
    fi
    echo ""

    # Validate font exists in system index
    if ! fc-list -- : family 2>/dev/null | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep -qiF "$FONT_FAMILY"; then
        echo "  Warning: '$FONT_FAMILY' was not found in the system font index."
        read -rp "  Proceed anyway? [y/N]: " _ans
        echo ""
        [[ ! "$_ans" =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }
    fi

    # --- Step 3: Scope ---
    echo "Step 3/3 — Choose where to apply the font override:"
    echo "  [1] Global only       — affects apps via ~/.config/fontconfig"
    echo "  [2] All Flatpak apps  — global + per-app overrides (most reliable)"
    echo ""
    read -rp "  Choice [1/2, default 1]: " _scope
    echo ""
    [[ "$_scope" == "2" ]] && APPLY_ALL="all"

    # Confirmation
    local _lang_name="${common_langs[$LANG_CODE]:-$LANG_CODE}"
    echo "========================================"
    echo "  Language : $LANG_CODE  ($_lang_name)"
    echo "  Font     : $FONT_FAMILY"
    echo "  Scope    : ${APPLY_ALL:+all Flatpak apps (global + per-app)}${APPLY_ALL:-global fontconfig only}"
    echo "========================================"
    read -rp "Proceed? [y/N]: " _ans
    echo ""
    [[ ! "$_ans" =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }
}

run_interactive_uninstall() {
    local conf_dir="$HOME/.config/fontconfig/conf.d"
    echo "=== Flatpak Font Uninstall Wizard ==="
    echo ""

    if [[ ! -d "$conf_dir" ]]; then
        echo "No font configuration directory found at $conf_dir"
        exit 0
    fi

    local files
    files=$(find "$conf_dir" -maxdepth 1 -name "99-*-fonts.conf" -printf "%f\n" | sort)

    if [[ -z "$files" ]]; then
        echo "No custom font configurations found."
        echo "Run without arguments to configure a new font."
        exit 0
    fi

    echo "Configured language fonts:"
    echo ""
    local file_array=() lang_array=()
    while IFS= read -r _file; do
        [[ -n "$_file" ]] || continue
        file_array+=("$_file")
        local _lang _font
        _lang=$(printf '%s' "$_file" | sed 's/^99-//;s/-fonts.conf$//')
        lang_array+=("$_lang")
        _font=$(grep -oP '(?<=<string>)[^<]+(?=</string>)' "$conf_dir/$_file" 2>/dev/null | head -1)
        printf "  [%2d]  %-14s  %s\n" "${#file_array[@]}" "$_lang" "${_font:-(unknown)}"
    done <<< "$files"

    echo ""
    local _total=${#file_array[@]}
    local _sel
    while true; do
        read -rp "Number to remove (1-$_total, or Enter to cancel): " _sel
        if [[ -z "$_sel" ]]; then
            echo "Aborted."
            exit 0
        fi
        if [[ "$_sel" =~ ^[0-9]+$ && "$_sel" -ge 1 && "$_sel" -le $_total ]]; then
            break
        fi
        echo "  Invalid selection. Enter a number from 1 to $_total."
    done

    local _idx=$(( _sel - 1 ))
    LANG_CODE="${lang_array[$_idx]}"

    echo ""
    read -rp "Remove font config for '$LANG_CODE'? [y/N]: " _ans
    echo ""
    if [[ ! "$_ans" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

apply_per_app_configs() {
    local lang=$1
    local font=$2
    
    echo "Applying per-app fontconfig for ALL installed Flatpak apps..."
    
    local count=0
    while IFS=$'\t' read -r name app_id rest; do
        [[ -z "$app_id" ]] && continue
        [[ "$app_id" == "Application" ]] && continue
        
        local app_conf_dir="$HOME/.var/app/$app_id/config/fontconfig/conf.d"
        local app_conf_file="$app_conf_dir/99-$lang-fonts.conf"
        local legacy_app_conf_file="$HOME/.var/app/$app_id/config/fontconfig/fonts.conf"
        
        mkdir -p "$app_conf_dir"
        
        # Remove legacy per-app config to avoid conflicting behavior
        rm -f "$legacy_app_conf_file"
        
        # Balanced config: gentle alias + targeted strong lang match
        cat > "$app_conf_file" <<EOFCONF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer><family>$font</family></prefer>
  </alias>
  <match target="pattern">
    <test name="lang" compare="contains">
      <string>$lang</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>$font</string>
    </edit>
  </match>
</fontconfig>
EOFCONF
        echo "  Applied to: $app_id"
        count=$((count + 1))
    done < <(flatpak list --app 2>/dev/null)
    
    echo "  Total apps configured: $count"
}

install_logic() {
    local lang=$1
    local font=$2
    local apply_all=$3
    local repo_root=$4

    local conf_dir="$HOME/.config/fontconfig/conf.d"
    local conf_file="$conf_dir/99-$lang-fonts.conf"

    echo "--- Setting up $font for language: $lang ---"

    mkdir -p "$conf_dir"

    if [[ -f "$conf_file" ]]; then
        read -p "Warning: Config file already exists at $conf_file. Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping file creation for $lang."
            return
        fi
    fi

    local repo_conf_file="$repo_root/configs/.config/fontconfig/conf.d/99-$lang-fonts.conf"

    if [[ -f "$repo_conf_file" ]]; then
        echo "Found existing config in repository: $repo_conf_file"
        echo "Copying to $conf_file..."
        cp "$repo_conf_file" "$conf_file"
    else
        echo "Generating new configuration at $conf_file..."
        cat > "$conf_file" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- Balanced font override for $lang -->
  
  <!-- 1. Gentle Suggestion for generic families (No tofu) -->
  <alias>
    <family>sans-serif</family>
    <prefer><family>$font</family></prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer><family>$font</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>$font</family></prefer>
  </alias>
  
  <!-- 2. Strong Priority for explicit $lang requests (Beats FreeSerif) -->
  <match target="pattern">
    <test name="lang" compare="contains">
      <string>$lang</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>$font</string>
    </edit>
  </match>
</fontconfig>
EOF
    fi

    echo "Applying global Flatpak overrides..."
    flatpak override --user --filesystem=xdg-config/fontconfig:ro --filesystem=~/.config/fontconfig:ro --filesystem=~/.local/share/fonts:ro --filesystem=/usr/share/fonts:ro --filesystem=/usr/share/fontconfig:ro
    
    if [[ "$apply_all" == "all" ]]; then
        echo ""
        apply_per_app_configs "$lang" "$font"
    fi
    
    echo "Refreshing font cache..."
    fc-cache -f
    
    echo ""
    echo "=== VERIFICATION ==="
    echo "Host system font match:"
    fc-match :lang=$lang
    
    echo ""
    echo "Flatpak runtime font match:"
    flatpak run --command=fc-match --app=org.freedesktop.Platform//24.08 :lang=$lang 2>/dev/null || \
    flatpak run --command=fc-match --app=org.freedesktop.Platform//23.08 :lang=$lang 2>/dev/null || \
    echo "(Could not test - no freedesktop runtime available)"
    
    echo ""
    echo "--- Done! Restart your Flatpak applications to see the changes. ---"
}

uninstall_logic() {
    local lang=$1
    local conf_file="$HOME/.config/fontconfig/conf.d/99-$lang-fonts.conf"

    if [[ -f "$conf_file" ]]; then
        echo "Removing font configuration for $lang at $conf_file..."
        rm -i "$conf_file"
    else
        echo "No global configuration found for language: $lang at $conf_file"
    fi

    echo "Removing per-app configurations for $lang..."
    find "$HOME/.var/app" -path "*/config/fontconfig/conf.d/99-$lang-fonts.conf" -type f -print -delete 2>/dev/null || true

    echo "Refreshing font cache..."
    fc-cache -f
    echo "Successfully uninstalled font config for $lang."

    # If no legacy configs remain AND sync isn't installed, offer to revoke grants
    local conf_dir="$HOME/.config/fontconfig/conf.d"
    local sync_file="$conf_dir/99-flatpak-host-sync.conf"
    local remaining=""
    if [[ -d "$conf_dir" ]]; then
        remaining=$(find "$conf_dir" -maxdepth 1 -name "99-*-fonts.conf" -printf "%f\n" 2>/dev/null)
    fi
    if [[ -z "$remaining" && ! -f "$sync_file" ]]; then
        echo ""
        read -rp "No font configs remain. Revoke global Flatpak filesystem grants too? [y/N]: " _ans
        if [[ "$_ans" =~ ^[Yy]$ ]]; then
            unsync_logic --grants-only
        fi
    fi
}

list_configs() {
    local conf_dir="$HOME/.config/fontconfig/conf.d"
    local sync_file="$conf_dir/99-flatpak-host-sync.conf"

    echo "=== Font Configuration ==="
    echo ""

    if general_fixes_installed; then
        echo "General font fixes: INSTALLED"
    else
        echo "General font fixes: not installed"
    fi
    if [[ -f "$sync_file" ]]; then
        echo "Sync status: INSTALLED  ($sync_file)"
    else
        echo "Sync status: not installed"
    fi
    echo ""

    echo "Active Flatpak filesystem grants (--user):"
    local grants
    grants=$(flatpak override --user --show 2>/dev/null | grep -E '^filesystems=' || true)
    if [[ -n "$grants" ]]; then
        echo "  ${grants#filesystems=}" | tr ';' '\n' | sed 's/^/    /'
    else
        echo "  (none)"
    fi
    echo ""

    echo "Legacy per-language configs:"
    if [[ ! -d "$conf_dir" ]]; then
        echo "  (none — $conf_dir does not exist)"
        return 0
    fi
    local files
    files=$(find "$conf_dir" -maxdepth 1 -name "99-*-fonts.conf" -printf "%f\n" | sort)
    if [[ -z "$files" ]]; then
        echo "  (none)"
        return 0
    fi
    printf "  %-12s %s\n" "LANGUAGE" "FONT"
    printf "  %-12s %s\n" "--------" "----"
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        local lang font_name
        lang=$(printf '%s' "$file" | sed 's/^99-//;s/-fonts.conf$//')
        font_name=$(grep -oP '(?<=<string>)[^<]+(?=</string>)' "$conf_dir/$file" 2>/dev/null | head -1)
        printf "  %-12s %s\n" "$lang" "${font_name:-(unknown)}"
    done <<< "$files"
    echo ""
    echo "To uninstall a legacy config: $0 uninstall <lang>"
}

# --- General host font fixes and Flatpak sync ---

GENERAL_FILE_NAME="99-system-ui.conf"
SYNC_FILE_NAME="99-flatpak-host-sync.conf"

general_fixes_installed() {
    [[ -f "$HOME/.config/fontconfig/conf.d/$GENERAL_FILE_NAME" ]]
}

write_general_font_fixes() {
    local target="$HOME/.config/fontconfig/conf.d/$GENERAL_FILE_NAME"
    local repo_template="$REPO_ROOT/configs/.config/fontconfig/conf.d/$GENERAL_FILE_NAME"
    mkdir -p "$(dirname "$target")"

    if [[ -f "$repo_template" ]]; then
        if [[ -f "$target" ]] && cmp -s "$repo_template" "$target"; then
            echo "  General font fixes already up to date: $target"
        else
            cp "$repo_template" "$target"
            echo "  Wrote general font fixes: $target"
        fi
    else
        cat > "$target" <<'EOFFIX'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- Keep Sarabun available explicitly, but out of generic system UI fallback. -->
  <match target="pattern">
    <test name="family" compare="eq">
      <string>system-ui</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans</string>
    </edit>
  </match>
</fontconfig>
EOFFIX
        echo "  Wrote general font fixes: $target"
    fi
}

install_general_logic() {
    echo "=== Installing general font fixes ==="
    write_general_font_fixes
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
SYNC_GRANTS=(host-os host-etc xdg-config/fontconfig ~/.local/share/fonts)

wipe_app_caches() {
    [[ -d "$HOME/.var/app" ]] || return 0
    find "$HOME/.var/app" -maxdepth 4 -type d -name fontconfig -path '*/cache/*' \
        -exec rm -rf {} + 2>/dev/null || true
}

detect_app_for_probe() {
    # User overrides apply to apps, not runtimes — probe via an installed app.
    flatpak list --app --columns=application 2>/dev/null \
        | grep -v '^Application$' \
        | head -1
}

sync_is_installed() {
    [[ -f "$HOME/.config/fontconfig/conf.d/$SYNC_FILE_NAME" ]]
}

write_sync_conf() {
    local target="$HOME/.config/fontconfig/conf.d/$SYNC_FILE_NAME"
    local repo_template="$REPO_ROOT/configs/.config/fontconfig/conf.d/$SYNC_FILE_NAME"
    mkdir -p "$(dirname "$target")"

    if [[ -f "$repo_template" ]]; then
        if [[ -f "$target" ]] && cmp -s "$repo_template" "$target"; then
            echo "  Sync conf already up to date: $target"
        else
            cp "$repo_template" "$target"
            echo "  Wrote sync conf from repo template: $target"
        fi
    else
        cat > "$target" <<'EOFSYNC'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <dir>/run/host/usr/share/fonts</dir>
  <dir prefix="xdg">fonts</dir>
  <include ignore_missing="yes" prefix="default">/run/host/etc/fonts/conf.d</include>
</fontconfig>
EOFSYNC
        echo "  Wrote sync conf: $target"
    fi
}

apply_sync_grants() {
    local args=()
    for g in "${SYNC_GRANTS[@]}"; do
        args+=(--filesystem="${g}:ro")
    done
    flatpak override --user "${args[@]}"
}

revoke_sync_grants() {
    local args=()
    for g in "${SYNC_GRANTS[@]}"; do
        args+=(--nofilesystem="$g")
    done
    flatpak override --user "${args[@]}"
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

    echo "Step 1/6 — Installing general host font fixes..."
    write_general_font_fixes

    # Warn if legacy configs exist
    local legacy
    legacy=$(find "$HOME/.config/fontconfig/conf.d" -maxdepth 1 -name "99-*-fonts.conf" \
        -printf "%f\n" 2>/dev/null \
        | sed 's/^99-//;s/-fonts\.conf$//' | paste -sd, -)
    if [[ -n "$legacy" ]]; then
        echo "  Note: legacy per-language configs active for: $legacy"
        echo "        Sync runs alongside them; if they conflict, legacy wins."
        echo ""
    fi

    echo "Step 2/6 — Writing Flatpak sync fontconfig snippet..."
    write_sync_conf

    echo "Step 3/6 — Applying global Flatpak filesystem grants..."
    apply_sync_grants
    echo "  Applied: ${SYNC_GRANTS[*]}"

    echo "Step 4/6 — Refreshing host font cache..."
    fc-cache -f >/dev/null

    echo "Step 5/6 — Wiping per-app fontconfig caches..."
    wipe_app_caches
    echo "  Done. Caches will rebuild on next app launch."

    echo "Step 6/6 — Verifying sandbox sees host fonts..."
    verify_sync

    echo ""
    echo "Done. Restart any already-running Flatpak apps to pick up the change."
}

unsync_logic() {
    local grants_only="${1:-}"
    echo "=== Reverting Flatpak host-fontconfig sync ==="
    echo ""

    if [[ "$grants_only" != "--grants-only" ]]; then
        local target="$HOME/.config/fontconfig/conf.d/$SYNC_FILE_NAME"
        if [[ -f "$target" ]]; then
            rm -f "$target"
            echo "  Removed: $target"
        else
            echo "  (no sync conf file to remove)"
        fi
    fi

    echo "  Revoking filesystem grants..."
    revoke_sync_grants
    echo "  Revoked: ${SYNC_GRANTS[*]}"
    echo "  General host font fixes remain installed; use '$0 unfix' to remove them."

    echo "  Refreshing host font cache..."
    fc-cache -f >/dev/null

    echo "  Wiping per-app fontconfig caches..."
    wipe_app_caches

    echo ""
    echo "Done. Restart any already-running Flatpak apps to pick up the change."
}

show_state() {
    echo "=== Flatpak Font State ==="
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

    echo "Active Flatpak --user overrides:"
    local raw
    raw=$(flatpak override --user --show 2>/dev/null || true)
    if [[ -z "$raw" ]]; then
        echo "  (none)"
    else
        printf '%s\n' "$raw" | sed 's/^/  /'
    fi
    echo ""

    echo "Host fc-match (a few common languages):"
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
    else
        echo "Sandbox probe: no Flatpak apps installed."
    fi
    echo ""

    local apps
    apps=$(flatpak list --app --columns=application 2>/dev/null | grep -v '^Application$' | wc -l)
    echo "Installed Flatpak apps: $apps"
}

show_main_menu() {
    while true; do
        echo ""
        echo "=== Font Setup ==="
        local host_th status general_status apps
        host_th=$(fc-match :lang=th 2>/dev/null | sed 's/^[^:]*: //')
        if sync_is_installed; then
            status="INSTALLED"
        else
            status="not installed"
        fi
        if general_fixes_installed; then
            general_status="INSTALLED"
        else
            general_status="not installed"
        fi
        apps=$(flatpak list --app --columns=application 2>/dev/null | grep -v '^Application$' | wc -l)
        echo "Host Thai (lang=th) resolves to: ${host_th:-?}"
        echo "General font fixes: $general_status"
        echo "Flatpak sync: $status  ($apps app(s) detected)"
        echo ""
        echo "  [1] Install general font fixes + Flatpak sync (recommended)"
        echo "  [2] Re-sync (after installing new apps or fonts)"
        echo "  [3] Show current state (dry-run)"
        echo "  [4] Uninstall Flatpak sync (keeps general fixes)"
        echo "  [5] Remove general font fixes"
        echo "  [6] Legacy: force a specific font for one language"
        echo "  [q] Quit"
        echo ""
        read -rp "Choice: " _choice
        echo ""
        case "$_choice" in
            1|2) install_sync_logic ;;
            3)   show_state ;;
            4)   unsync_logic ;;
            5)   uninstall_general_logic ;;
            6)
                run_interactive_install
                install_logic "$LANG_CODE" "$FONT_FAMILY" "${APPLY_ALL:-}" "$REPO_ROOT"
                # legacy_install may exit on user abort; only reach here on success
                ;;
            q|Q|"") echo "Bye."; return 0 ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

# --- Main ---

check_dependencies
REPO_ROOT=$(get_repo_root)

if [[ $# -eq 0 ]]; then
    show_main_menu
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
elif [[ "$1" == "fix" ]]; then
    install_general_logic
elif [[ "$1" == "sync" ]]; then
    install_sync_logic
elif [[ "$1" == "unfix" ]]; then
    uninstall_general_logic
elif [[ "$1" == "unsync" ]]; then
    unsync_logic
elif [[ "$1" == "state" ]]; then
    show_state
elif [[ "$1" == "list" ]]; then
    list_configs
elif [[ "$1" == "uninstall" ]]; then
    if [[ -z "$2" ]]; then
        run_interactive_uninstall
        uninstall_logic "$LANG_CODE"
    else
        uninstall_logic "$2"
    fi
else
    if [[ -z "$2" ]]; then
        show_usage
        exit 1
    fi
    install_logic "$1" "$2" "$3" "$REPO_ROOT"
fi
