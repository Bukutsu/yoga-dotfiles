#!/usr/bin/env bash
set -euo pipefail

backup="${XDG_STATE_HOME:-$HOME/.local/state}/cosmic-keybindings-gnome/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
dconf dump /org/gnome/desktop/wm/keybindings/ > "$backup/wm.dconf"
dconf dump /org/gnome/shell/keybindings/ > "$backup/shell.dconf"
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$backup/media-keys.dconf"
echo "Backup: $backup"

# Keep GNOME's dynamic workspaces. Free COSMIC's Super+number bindings.
gsettings set org.gnome.mutter dynamic-workspaces true
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
  gsettings set org.gnome.shell.keybindings open-new-window-application-$i "[]"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
done
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']"

# Native GNOME window operations.
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>m', '<Alt>F10']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>F11']"
gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>r', '<Alt>F8']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>h']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Super>0']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "['<Super><Shift>0']"

# COSMIC treats H/Left/K/Up as previous and J/Down/L/Right as next.
# GNOME's workspace strip is horizontal, so route those through left/right.
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up', '<Super>KP_Prior', '<Super><Alt>Left', '<Control><Alt>Left', '<Super><Ctrl>Left', '<Super><Ctrl>Up', '<Super><Ctrl>h', '<Super><Ctrl>k']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down', '<Super>KP_Next', '<Super><Alt>Right', '<Control><Alt>Right', '<Super><Ctrl>Right', '<Super><Ctrl>Down', '<Super><Ctrl>j', '<Super><Ctrl>l']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Control><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Control><Alt>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>Page_Up', '<Super><Shift>KP_Prior', '<Super><Shift><Alt>Left', '<Control><Shift><Alt>Left', '<Super><Ctrl><Shift>Left', '<Super><Ctrl><Shift>Up', '<Super><Ctrl><Shift>h', '<Super><Ctrl><Shift>k']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>Page_Down', '<Super><Shift>KP_Next', '<Super><Shift><Alt>Right', '<Control><Shift><Alt>Right', '<Super><Ctrl><Shift>Right', '<Super><Ctrl><Shift>Down', '<Super><Ctrl><Shift>j', '<Super><Ctrl><Shift>l']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Control><Shift><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Control><Shift><Alt>Down']"

# Preserve GNOME's Super+Shift+Arrow monitor movement and add COSMIC's Alt variants.
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Super><Shift>Left', '<Super><Shift><Alt>Left', '<Super><Shift><Alt>h']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Super><Shift>Down', '<Super><Shift><Alt>Down', '<Super><Shift><Alt>j']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Super><Shift>Up', '<Super><Shift><Alt>Up', '<Super><Shift><Alt>k']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right', '<Super><Shift><Alt>Right', '<Super><Shift><Alt>l']"

# Shell and applications.
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>w', '<Super>slash']"
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>f']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>b']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>Escape', '<Super>l']"
gsettings set org.gnome.settings-daemon.plugins.media-keys logout "['<Super><Shift>Escape', '<Control><Alt>Delete']"

# Preserve existing custom shortcuts while adding Super+T.
path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/cosmic-terminal/'
current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
# Remove the legacy entry created by older versions of this script.
legacy="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-terminal/'"
current="${current//$legacy, /}"
current="${current//, $legacy/}"
current="${current//$legacy/}"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$current"
dconf reset -f /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-terminal/
if [[ "$current" != *"$path"* ]]; then
  [[ "$current" == '@as []' ]] && current='[]'
  current="${current%]}"
  [[ "$current" != '[' ]] && current+=", "
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$current'$path']"
fi
terminal="$(command -v ptyxis || command -v gnome-terminal || command -v kgx || command -v x-terminal-emulator || true)"
if [[ -n "$terminal" ]]; then
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
  gsettings set "$schema" name 'Terminal'
  gsettings set "$schema" command "$terminal"
  gsettings set "$schema" binding '<Super>t'
else
  echo 'Warning: no supported terminal executable found; Super+T was not configured.' >&2
fi

# PaperWM ships a private schema, so it must be addressed through --schemadir.
paperwm="$HOME/.local/share/gnome-shell/extensions/paperwm@paperwm.github.com"
if [[ -f "$paperwm/schemas/gschemas.compiled" ]] && gnome-extensions info paperwm@paperwm.github.com 2>/dev/null | grep -q 'Enabled: Yes'; then
  pw=(gsettings --schemadir "$paperwm/schemas" set org.gnome.shell.extensions.paperwm.keybindings)

  # Directional focus and movement.
  "${pw[@]}" switch-left "['<Super>h', '<Super>Left']"
  "${pw[@]}" switch-down "['<Super>j', '<Super>Down']"
  "${pw[@]}" switch-up "['<Super>k', '<Super>Up']"
  "${pw[@]}" switch-right "['<Super>l', '<Super>Right']"
  "${pw[@]}" move-left "['<Super><Shift>h', '<Super><Shift>Left']"
  "${pw[@]}" move-down "['<Super><Shift>j', '<Super><Shift>Down']"
  "${pw[@]}" move-up "['<Super><Shift>k', '<Super><Shift>Up']"
  "${pw[@]}" move-right "['<Super><Shift>l', '<Super><Shift>Right']"

  # Directional monitor focus and window movement.
  "${pw[@]}" switch-monitor-left "['<Super><Alt>h', '<Super><Alt>Left']"
  "${pw[@]}" switch-monitor-below "['<Super><Alt>j', '<Super><Alt>Down']"
  "${pw[@]}" switch-monitor-above "['<Super><Alt>k', '<Super><Alt>Up']"
  "${pw[@]}" switch-monitor-right "['<Super><Alt>l', '<Super><Alt>Right']"
  "${pw[@]}" move-monitor-left "['<Super><Shift><Alt>h', '<Super><Shift><Alt>Left']"
  "${pw[@]}" move-monitor-below "['<Super><Shift><Alt>j', '<Super><Shift><Alt>Down']"
  "${pw[@]}" move-monitor-above "['<Super><Shift><Alt>k', '<Super><Shift><Alt>Up']"
  "${pw[@]}" move-monitor-right "['<Super><Shift><Alt>l', '<Super><Shift><Alt>Right']"

  # PaperWM's scratch toggle is its supported tiled/floating equivalent.
  "${pw[@]}" toggle-scratch "['<Super>g']"

  # Release PaperWM defaults that collide with COSMIC system shortcuts.
  for key in take-window toggle-scratch-window toggle-scratch-layer toggle-maximize-width cycle-width switch-next switch-previous; do
    "${pw[@]}" "$key" "[]"
  done
  echo 'Applied PaperWM directional focus, move, and monitor bindings.'
else
  echo 'PaperWM inactive; keeping stock GNOME window bindings.'
fi

echo 'Applied COSMIC bindings.'
