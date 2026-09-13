# Yoga 7 14AKP10 dotfiles

Configs for my Lenovo Yoga 7 2-in-1 (14AKP10) running Linux.

## Apply

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd yoga-dotfiles
```

Copies overwrite whatever is already at the destination, so back things up first.

### User configs

All at once:

```bash
cp -r configs/.config/. ~/.config/
```

Or pick what you need:

```bash
cp -r configs/.config/niri ~/.config/
cp -r configs/.config/wluma ~/.config/
cp -r configs/.config/alacritty ~/.config/
cp -r configs/.config/kitty ~/.config/
cp -r configs/.config/fontconfig ~/.config/
```

EasyEffects 8 keeps its presets outside `~/.config`:

```bash
cp -r configs/.local/share/easyeffects ~/.local/share/
```

Restart the app you copied config for. Log out and back in for compositor changes. Niri starts `wluma` and `iio-niri` on its own. `wluma` learns your preferred brightness after you adjust it manually a few times in different lighting. EasyEffects finds its presets after a restart. Load one from its UI. Autoload maps the internal speaker to `Dolby-Laptop-Balanced` and the USB DAC to `Default`. Speaker details live in `docs/AUDIO.md`.

### System configs

Install these one at a time:

```bash
# Copilot key remap, needs keyd
sudo install -Dm644 configs/system/etc/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd

# Wi-Fi power saving off
sudo install -Dm644 configs/system/etc/NetworkManager/conf.d/disable-wifi-powersave.conf \
  /etc/NetworkManager/conf.d/disable-wifi-powersave.conf
sudo systemctl restart NetworkManager
```

`docs/COPILOT_KEY.md` has more on the remap. `docs/THAI_FONT_FALLBACK.md` covers Thai UI fallback. Fontconfig fixes for Flatpaks live in [fontconfig-flatpak-fonts](https://github.com/Bukutsu/fontconfig-flatpak-fonts).

## Required packages

`niri` `plasma-desktop` `alacritty` `kitty` `dolphin` `iio-sensor-proxy` `iio-niri` `wluma` `keyd` `wireplumber` `jq` `tensaku` `easyeffects`

## License

License is MIT, see [LICENSE](LICENSE).
