# Yoga 7 14AKP10 System Configuration

Personal documentation and configuration files for Lenovo Yoga 7 2-in-1 (14AKP10) running Arch Linux.

## Contents

- **docs/** — Setup guides and hardware notes
- **configs/** — Config files mirroring their target paths
  - `configs/system/` → `/etc/`
  - `configs/niri/.config/` → `~/.config/`
- **scripts/** — Automation tools

## Quick Start

```bash
git clone https://github.com/Bukutsu/yoga-dotfiles.git
cd Yoga-7-14AKP10-Linux-Config

# Read the relevant guide first
cat docs/INSTALL_GUIDE.md

# System configs (/etc/)
sudo cp -r configs/system/* /etc/

# Niri + iio-niri (user configs)
cp -r configs/niri/.config/* ~/.config/
systemctl --user daemon-reload
systemctl --user enable --now iio-niri.service
```

## Docs

- [INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md) — Fresh installation
- [AUDIO_TUNING.md](docs/AUDIO_TUNING.md) — Speaker and EasyEffects setup
- [AUDIO_RESEARCH.md](docs/AUDIO_RESEARCH.md) — Hardware analysis and tuning research
- [BIOPASS_PAM_SETUP.md](docs/BIOPASS_PAM_SETUP.md) — Face authentication
- [DEBRANDING.md](docs/DEBRANDING.md) — Remove CachyOS branding
- [LIMINE_THEMING.md](docs/LIMINE_THEMING.md) — Bootloader customization
- [TRANSFORM_TO_ARCH.md](docs/TRANSFORM_TO_ARCH.md) — CachyOS to Arch migration

## Device

- CPU: AMD Ryzen AI 7 350
- RAM: 32GB LPDDR5X
- Audio: Realtek ALC3306 (4-speaker)
- WiFi: Realtek RTL8922AE
- Display: 14" 2.8K OLED 120Hz

## License

MIT — See [LICENSE](LICENSE)
