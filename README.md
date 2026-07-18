# Yoga 7 14AKP10 System Configuration

Personal documentation and configuration files for Lenovo Yoga 7 2-in-1 (14AKP10) running Arch Linux.

## Apply the configs

Clone the repository, enter it, then apply only the sections you use:

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd yoga-dotfiles
```

Existing files at the destinations are overwritten, so back them up first.

### Desktop configs

```bash
# Niri and DankMaterialShell themes
cp -r configs/niri/.config/. ~/.config/

# Noctalia
cp -r configs/noctalia/.config/. ~/.config/

# Hyprland
cp -r configs/hypr/.config/. ~/.config/

# Alacritty
cp -r configs/alacritty/.config/. ~/.config/

# Kitty
mkdir -p ~/.config/kitty
cp configs/kitty/* ~/.config/kitty/
```

Restart the relevant application. Log out and back in after applying a compositor config. Niri starts `iio-niri` from `config.kdl`.

### KDE Plasma

Log out of Plasma first so it does not overwrite the copied settings, then run from a TTY or another desktop:

```bash
cp -r configs/kde/.config/. ~/.config/
cp -r configs/kde/.local/. ~/.local/
```

Log back in to apply the settings and bundled look-and-feel themes.

### System configs

Apply these individually rather than copying all of `configs/system`:

```bash
# Copilot key remap
sudo install -Dm644 configs/system/etc/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd

# Disable NetworkManager Wi-Fi power saving
sudo install -Dm644 configs/system/etc/NetworkManager/conf.d/disable-wifi-powersave.conf \
  /etc/NetworkManager/conf.d/disable-wifi-powersave.conf
sudo systemctl restart NetworkManager

# scx_loader scheduler configuration
sudo install -Dm644 configs/system/etc/scx_loader.toml /etc/scx_loader.toml
sudo systemctl enable --now scx_loader

# Factory display color profile
sudo install -Dm644 configs/system/usr/share/color/icc/colord/Yoga14AKp10.icm \
  /usr/share/color/icc/colord/Yoga14AKp10.icm
```

Select the installed ICC profile in your desktop's color settings; see [COLOR_MANAGEMENT.md](docs/COLOR_MANAGEMENT.md). The key remap also requires `keyd`; see [COPILOT_KEY.md](docs/COPILOT_KEY.md).

### EasyEffects audio presets

```bash
mkdir -p ~/.config/easyeffects/{irs,output}
cp configs/audio/easyeffects_irs/* ~/.config/easyeffects/irs/
cp configs/audio/easyeffects_presets/*.json ~/.config/easyeffects/output/
cp configs/audio/easyeffects_presets/ThinkPad_Z16_Dolby/*.json ~/.config/easyeffects/output/
```

Open EasyEffects and load one preset. See [AUDIO_TUNING.md](docs/AUDIO_TUNING.md) for the differences.

### Fontconfig and Flatpak fonts

Use the included script; it installs the files under `configs/fontconfig` and configures Flatpak access:

```bash
./scripts/setup-flatpak-fonts.sh sync
./scripts/setup-flatpak-fonts.sh state   # verify
```

Run `./scripts/setup-flatpak-fonts.sh unsync` to remove it.

## Docs

- [INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md) — Fresh installation
- [AUDIO_TUNING.md](docs/AUDIO_TUNING.md) — Speaker and EasyEffects setup
- [COLOR_MANAGEMENT.md](docs/COLOR_MANAGEMENT.md) — Display color profile configuration
- [COPILOT_KEY.md](docs/COPILOT_KEY.md) — Copilot key remap via keyd for KDE
- [TRANSFORM_TO_ARCH.md](docs/TRANSFORM_TO_ARCH.md) — CachyOS to Arch migration
- [DDC_CI_MONITOR_CONTROL.md](docs/DDC_CI_MONITOR_CONTROL.md) — External monitor input switching via DDC/CI

## Device

- CPU: AMD Ryzen AI 7 350
- RAM: 32GB LPDDR5X
- Audio: Realtek ALC3306 (4-speaker)
- WiFi: Realtek RTL8922AE
- Display: 14" 2.8K OLED 120Hz (with X-Rite factory color profile)

## Niri shortcuts

- `Mod+Alt+I` — toggle the built-in `eDP-1` display (requires `jq`)

## Dependencies

Ensure these are installed for all keybinds and hardware configs to work:

### Core & Shell
- **Compositors:** `niri`, `hyprland`, `plasma-desktop`
- **Shell/UI:** `noctalia` (primary panel/launcher), `dms` (alternative)
- **Terminal/Files:** `alacritty`, `kitty`, `dolphin`

### Hardware & System
- **Auto-rotate:** `iio-sensor-proxy`, `iio-niri`, `iio-hyprland`
- **Key Remapping (Copilot Key):** `keyd`
- **Scheduling:** `scx-scheds` (for `scx_loader`)
- **Audio Tuning:** `easyeffects`

### Utilities & Media
- **Screenshot:** `noctalia` (wlr-screencopy) + `satty` (annotation)
- **Media/Brightness:** `wireplumber` (`wpctl`), `playerctl`, `brightnessctl`
- **Config scripting:** `jq`

## License

MIT — See [LICENSE](LICENSE)
