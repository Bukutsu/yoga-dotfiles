# Yoga 7 14AKP10 dotfiles

Configs for my Lenovo Yoga 7 2-in-1 (14AKP10) running Arch Linux.

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
cp -r configs/.config/noctalia ~/.config/
cp -r configs/.config/hypr ~/.config/
cp -r configs/.config/alacritty ~/.config/
cp -r configs/.config/kitty ~/.config/
cp -r configs/.config/gtk-3.0 ~/.config/
cp -r configs/.config/gtk-4.0 ~/.config/
cp -r configs/.config/fontconfig ~/.config/
cp configs/.config/mimeapps.list ~/.config/mimeapps.list
```

EasyEffects 8 keeps its presets outside `~/.config`:

```bash
cp -r configs/.local/share/easyeffects ~/.local/share/
```

Restart whichever app you copied config for, and log out and back in for compositor changes. Niri starts `wluma` and `iio-niri` on its own. `wluma` learns your preferred brightness after you adjust it manually a few times in different lighting. The GTK directories set Papirus-Dark icons. EasyEffects finds its presets after a restart; load one from its UI. Autoload binds the Yoga speaker route to Z16-Dynamic-Balanced and falls back to Default everywhere else.

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

`docs/COPILOT_KEY.md` has more on the remap. Thai UI fallback is documented in `docs/THAI_FONT_FALLBACK.md`. Fontconfig fixes for Flatpaks live in [fontconfig-flatpak-fonts](https://github.com/Bukutsu/fontconfig-flatpak-fonts).

## Packages these configs expect

`niri` `hyprland` `plasma-desktop` `noctalia` `alacritty` `kitty` `dolphin` `iio-sensor-proxy` `iio-niri` `wluma` `keyd` `wireplumber` `jq` `tensaku` `easyeffects`

## Hardware

Ryzen AI 7 350, 32GB LPDDR5X, Realtek ALC3306 with four speakers, Realtek RTL8922AE WiFi, 14" 2.8K OLED at 120Hz.

## License

MIT, see [LICENSE](LICENSE).
