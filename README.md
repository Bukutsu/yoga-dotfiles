# Yoga 7 14AKP10 System Configuration

Personal documentation and configuration files for Lenovo Yoga 7 2-in-1 (14AKP10) running Arch Linux.

## Apply the configs

Clone the repository, enter it, then apply only the sections you use:

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd yoga-dotfiles
```

Existing files at the destinations are overwritten, so back them up first.

### User configs

Copy all configuration directories to your system:

```bash
# Copy all desktop configuration files
cp -r configs/.config/. ~/.config/

# Copy all user-level local files (including custom KDE global layouts)
cp -r configs/.local/. ~/.local/
```

Alternatively, copy individual configurations:

```bash
# Niri & DankMaterialShell
cp -r configs/.config/niri ~/.config/
cp -r configs/.config/DankMaterialShell ~/.config/

# Niri ambient-light auto-brightness (wluma)
cp -r configs/.config/wluma ~/.config/

# Noctalia
cp -r configs/.config/noctalia ~/.config/

# Hyprland
cp -r configs/.config/hypr ~/.config/

# Alacritty
cp -r configs/.config/alacritty ~/.config/

# Kitty
cp -r configs/.config/kitty ~/.config/

# MIME default applications
cp configs/.config/mimeapps.list ~/.config/mimeapps.list

# EasyEffects audio presets
cp -r configs/.config/easyeffects ~/.config/
```

Restart the relevant application. Log out and back in after applying a compositor config. Niri starts `wluma` and `iio-niri` from `config.kdl`. `wluma` learns your preferred brightness after several manual adjustments in different lighting conditions.

### KDE Plasma

Log out of Plasma first so it does not overwrite the copied settings, then copy the user configurations (`.config` and `.local`) from a TTY or another desktop session. Log back in to apply.

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

Open EasyEffects and load one preset. See [AUDIO_TUNING.md](docs/AUDIO_TUNING.md) for the differences.

### Fontconfig fixes and Flatpak fonts

Use the included script for host-wide font fixes and optional Flatpak access:

```bash
./scripts/setup-fonts.sh fix    # host fixes only
./scripts/setup-fonts.sh sync   # host fixes + Flatpak access
./scripts/setup-fonts.sh state  # verify
```

Run `./scripts/setup-fonts.sh unfix` to remove host fixes or `unsync` to remove only Flatpak access.

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

- `Mod+A` / `Mod+/` — Noctalia launcher
- `Mod+I` — Noctalia control center
- `Mod+Shift+I` — Noctalia settings
- `Mod+C` — Noctalia clipboard
- `Mod+Escape` — Noctalia session panel
- `Mod+P` — cycle power profile
- `Mod+Shift+Escape` — log out
- `Print` — fullscreen screenshot
- `Mod+Shift+S` — region screenshot
- `Mod+Alt+I` — toggle the built-in `eDP-1` display (requires `jq`)

Noctalia-specific bindings live in `configs/.config/niri/cfg/noctalia-integration.kdl`.

## Dependencies

Ensure these are installed for all keybinds and hardware configs to work:

### Core & Shell
- **Compositors:** `niri`, `hyprland`, `plasma-desktop`
- **Shell/UI:** `noctalia` (primary panel/launcher), `dms` (alternative)
- **Terminal/Files:** `alacritty`, `kitty`, `dolphin`

### Hardware & System
- **Auto-rotate:** `iio-sensor-proxy`, `iio-niri`, `iio-hyprland`
- **Auto-brightness:** `wluma`, `iio-sensor-proxy`
- **Key Remapping (Copilot Key):** `keyd`
- **Scheduling:** `scx-scheds` (for `scx_loader`)
- **Audio Tuning:** `easyeffects`

### Utilities & Media
- **Screenshot:** `noctalia` (wlr-screencopy) + `satty` (annotation)
- **Media/Brightness:** `wireplumber` (`wpctl`), `playerctl`, `brightnessctl`
- **Config scripting:** `jq`

## License

MIT — See [LICENSE](LICENSE)
