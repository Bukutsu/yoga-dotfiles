# Yoga 7 14AKP10 System Configuration

Personal documentation and configuration files for Lenovo Yoga 7 2-in-1 (14AKP10) running Arch Linux.

## Contents

- **docs/** — Setup guides and hardware notes
- **configs/** — Config files mirroring their target paths
  - `configs/system/etc/` → `/etc/`
  - `configs/system/usr/` → `/usr/`
  - `configs/niri/.config/niri/` → `~/.config/niri/`
  - `configs/hypr/.config/hypr/` → `~/.config/hypr/`
  - `configs/alacritty/.config/alacritty/` → `~/.config/alacritty/`
  - `configs/kde/` → `~/`
- **scripts/** — Automation tools

## Quick Start

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd Yoga-7-14AKP10-Linux-Config

# Read the relevant guide first
cat docs/INSTALL_GUIDE.md

# System configs (/etc/)
sudo cp -r configs/system/etc/. /etc/

# Niri + iio-niri
cp -r configs/niri/.config/niri ~/.config/

# Hyprland
cp -r configs/hypr/.config/hypr ~/.config/

# Alacritty
cp -r configs/alacritty/.config/alacritty ~/.config/

# KDE Plasma (Log out first to prevent settings from being overwritten on exit)
cp -r configs/kde/.config/. ~/.config/
cp -r configs/kde/.local/. ~/.local/

# iio-niri starts with Niri from config.kdl; restart the session to apply.
```

## Docs

- [INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md) — Fresh installation
- [AUDIO_TUNING.md](docs/AUDIO_TUNING.md) — Speaker and EasyEffects setup
- [BIOPASS_PAM_SETUP.md](docs/BIOPASS_PAM_SETUP.md) — Face authentication
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

## License

MIT — See [LICENSE](LICENSE)

