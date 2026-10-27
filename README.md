# Yoga 7 14AKP10 dotfiles

My Linux configs for the Lenovo Yoga 7 2-in-1 (14AKP10), including niri, wluma, EasyEffects speaker presets, and a Copilot key remap.

## Install

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd yoga-dotfiles
```

Back up your existing configs first. These copy commands overwrite files at the destination.

### User configs

Copy all user configs:

```bash
cp -r configs/.config/. ~/.config/
```

Or copy only what you need:

```bash
cp -r configs/.config/niri ~/.config/
cp -r configs/.config/wluma ~/.config/
cp -r configs/.config/alacritty ~/.config/
cp -r configs/.config/kitty ~/.config/
cp -r configs/.config/ghostty ~/.config/
cp -r configs/.config/fontconfig ~/.config/
```

EasyEffects 8 keeps its presets outside `~/.config`:

```bash
cp -r configs/.local/share/easyeffects ~/.local/share/
```

Restart each app after copying its config. For compositor changes, log out and back in. Niri starts `wluma` and `iio-niri` automatically.

Adjust the brightness manually a few times in different lighting so `wluma` can learn your preferences.

Restart EasyEffects to load the presets, then choose one in the UI. Autoload applies `Dolby-Laptop-Balanced` only to the internal speaker. Set `Default` as the output fallback preset for all other outputs. See `docs/AUDIO.md` for the presets and speaker setup.

### System configs

Install the system configs you need, one at a time:

```bash
# Copilot key remap, needs keyd
sudo install -Dm644 configs/system/etc/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd

# Wi-Fi power saving off
sudo install -Dm644 configs/system/etc/NetworkManager/conf.d/disable-wifi-powersave.conf \
  /etc/NetworkManager/conf.d/disable-wifi-powersave.conf
sudo systemctl restart NetworkManager
```

See `docs/COPILOT_KEY.md` for remap details, `docs/THAI_FONT_FALLBACK.md` for Thai UI font fallback, and `docs/FACE_UNLOCK.md` for IR face unlock and the deferred NPU setup. Fontconfig fixes for Flatpaks are in [fontconfig-flatpak-fonts](https://github.com/Bukutsu/fontconfig-flatpak-fonts).

## Required packages

Compositor and desktop: `niri` `plasma-desktop`

Terminals and files: `alacritty` `kitty` `dolphin`

Rotation and brightness: `iio-sensor-proxy` `iio-niri` `wluma`

Input and audio: `keyd` `wireplumber` `easyeffects`

Utilities: `jq` `tensaku`

## License

MIT, see [LICENSE](LICENSE).
