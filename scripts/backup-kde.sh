#!/bin/bash
# Backup KDE Plasma configuration files to dotfiles repo
# ponytail: simple cp script, upgrade to rsync or a config-list loop if files grow

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
DEST_CONFIG="$REPO_ROOT/configs/kde/.config"
DEST_SHARE="$REPO_ROOT/configs/kde/.local/share"

mkdir -p "$DEST_CONFIG"
mkdir -p "$DEST_SHARE/plasma/look-and-feel"

# Copy KDE config files, skipping kitty
for f in "$HOME"/.config/k* "$HOME"/.config/plasma*; do
    name="$(basename "$f")"
    if [ "$name" = "kitty" ]; then
        continue
    fi
    if [ -f "$f" ]; then
        cp -p "$f" "$DEST_CONFIG/"
    elif [ -d "$f" ] && [[ "$name" =~ ^(kdeconnect|kate|kdedefaults|plasma-nm|plasma-workspace)$ ]]; then
        rsync -ar --exclude='*.pem' "$f/" "$DEST_CONFIG/$name/"
    fi
done

# Copy custom look-and-feel layouts
if [ -d "$HOME/.local/share/plasma/look-and-feel" ]; then
    cp -pr "$HOME"/.local/share/plasma/look-and-feel/* "$DEST_SHARE/plasma/look-and-feel/"
fi

echo "KDE configuration backed up to $REPO_ROOT/configs/kde"
