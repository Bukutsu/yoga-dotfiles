# Yoga 7 Strix Point: Pure Arch + Limine Installation Guide

**Goal**: Maximum longevity + verified 3–4W idle power efficiency.

---

## Phase 1: Base Installation (archinstall)
1. Boot **[Arch Linux ISO](https://archlinux.org/download/)**.
2. Connect WiFi:
   ```bash
   iwctl
   # station wlan0 connect YourSSID
   ```
3. Run `archinstall` with these options:
   *   **Disk**: `Btrfs` (snapshots for safety).
   *   **Bootloader**: `Limine` (perfect for single kernel + Btrfs).
   *   **Kernel**: `linux`.
   *   **Graphics**: `AMD / ATI (open-source)`.
   *   **Audio**: `Pipewire`.
   *   **Network**: `NetworkManager`.
   *   Enable `multilib`.
4. **Reboot** into your new Arch system.

---

## Phase 2: Add CachyOS Hybrid Repository
**Follow the [Official CachyOS Wiki Guide](https://wiki.cachyos.org/features/optimized_repos/#adding-our-repositories-to-an-existing-arch-linux-install)** to safely add the CachyOS repository.

---

## Phase 3: Install Optimized Packages
```bash
sudo pacman -S \
    linux-cachyos \
    linux-cachyos-headers \
    scx-scheds \
    scx-tools \
    scx-manager \
    power-profiles-daemon \
    powertop \
    git
```

---

## Phase 4: Apply Kernel Parameters (Limine)
Edit your Limine configuration (typically `/etc/default/limine` or `/boot/limine/limine.conf` depending on how it was installed):
```bash
sudo micro /etc/default/limine
```
Find your kernel command line entry and append your verified flags:
```text
amd_pstate=active pcie_aspm=force
```
If using the wrapper script, update Limine:
```bash
sudo limine-update
```

### Optional: Theming Limine (Tokyo Night Dark)
You can customize the bootloader colors by editing `/boot/limine.conf` and replacing the theme palette:
```conf
# Tokyo Night Dark theme
term_palette: 15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6
term_palette_bright: 414868;ff899d;9fe044;faba4a;8db0ff;c7a9ff;a4daff;c0caf5
term_background: 1a1b26
term_foreground: c0caf5
term_background_bright: 414868
term_foreground_bright: c0caf5
interface_branding:
```
Deploy changes:
```bash
sudo limine-update
```

---

## Phase 5: Enable Services
```bash
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now scx_loader
```

---

## Phase 6: Configure Scheduler (scx-manager)
1. Launch **`scx-manager`** from your application menu.
2. Select **`scx_lavd`** as the scheduler.
3. Configure modes with your verified flags:

| Mode | Flags |
| :--- | :--- |
| **Auto** | `--autopower --cpu-pref-order 4,12,6,14,0,8,2,10,1,3,5,7,9,11,13,15 --lb-low-util-pct 10` |
| **Performance** | `--performance --cpu-pref-order 4,12,6,14,0,8,2,10,1,3,5,7,9,11,13,15 --lb-low-util-pct 0` |
| **Balanced** | `--balanced --cpu-pref-order 4,12,6,14,0,8,2,10,1,3,5,7,9,11,13,15 --lb-low-util-pct 25` |
| **Power-Saver** | `--powersave --cpu-pref-order 4,12,6,14,0,8,2,10,1,3,5,7,9,11,13,15 --lb-low-util-pct 70` |

4. Set default to **`Auto`** (syncs with power-profiles-daemon).

---

## Phase 7: Optional: Deploy WiFi Stability Fix
```bash
sudo install -Dm644 configs/system/etc/NetworkManager/conf.d/disable-wifi-powersave.conf \
  /etc/NetworkManager/conf.d/disable-wifi-powersave.conf
sudo systemctl restart NetworkManager
```

---

## Phase 8: Verification
1. **Idle Power**: `sudo powertop` → **Target: 3–4W**
2. **YouTube**: Play 1080p video → **Target: 6–7W**
3. **Scheduler**: `scx_loader status` or check in `scx-manager`.

---

## Phase 9: Hardware Polish (Optional)

### Windows Hello-style Face Unlock (IR Camera)
The Yoga 7 features a hardware Infrared camera that works perfectly on Linux for facial recognition authentication (sudo, login, lock screen).
*   **Tool**: `howdy`
*   **Installation**: Follow the official [Arch Wiki for Howdy](https://wiki.archlinux.org/title/Howdy) to install and configure the PAM modules for your specific Desktop Environment.

### Battery Conservation Mode
If you leave your laptop plugged in frequently, you can preserve the battery's chemical lifespan by limiting the hardware charge to 80%.
*   **GNOME/KDE**: This is natively supported. Look for "Charge Limit" or "Conservation Mode" in your desktop environment's Power settings.

### Color Calibration (OLED Display Profile)
Apply the factory-calibrated X-Rite color profile for the 14" 2.8K OLED display to ensure color accuracy:
*   **Guide**: See [COLOR_MANAGEMENT.md](COLOR_MANAGEMENT.md) for installation and application instructions.

---

## Exit Strategy (If CachyOS Disappears)
1. Remove CachyOS repo from `/etc/pacman.conf`.
2. `scx-manager` stays installed (no updates, but keeps working).
3. Optionally install standard `linux` kernel: `sudo pacman -S linux linux-headers`.