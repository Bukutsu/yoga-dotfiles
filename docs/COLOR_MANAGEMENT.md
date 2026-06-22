# Color Management for Lenovo Yoga 7 (14AKP10)

This directory contains the factory-calibrated color profile for the Lenovo Yoga 7 2-in-1 (14AKP10) featuring the **14" 2.8K (2880x1800) OLED 120Hz** display.

The ICC profile file is located in the repository at:
[Yoga14AKp10.icm](file:///home/bukutsu/Projects/yoga-dotfiles/configs/system/usr/share/color/icc/colord/Yoga14AKp10.icm)

---

## Profile Details

*   **Profile Name / Description:** `Yoga14AKp10.icm`
*   **Calibration Source:** Factory calibration by **X-Rite, Inc.** (XRCM)
*   **Format:** Microsoft Color Profile 2.1 (RGB / XYZ-mntr device)
*   **Target Panel:** 14" 2.8K OLED (Samsung/Lenovo 120Hz panel)
*   **Verify Verification Info:** 
    ```bash
    file configs/system/usr/share/color/icc/colord/Yoga14AKp10.icm
    ```
    *Output:* `Microsoft color profile 2.1, RGB/XYZ-mntr device by XRCM, 9824 bytes, 2-5-2025 12:27:42, 0x2 vendor flags "Yoga14AKp10.icm"`

---

## Installation

### Step 1: Copy Profile to System Directory
To make the profile available to the system-wide color manager daemon (`colord`), copy it to the standard directory:

```bash
sudo mkdir -p /usr/share/color/icc/colord/
sudo cp configs/system/usr/share/color/icc/colord/Yoga14AKp10.icm /usr/share/color/icc/colord/
```

### Step 2: Apply in Desktop Environments

#### GNOME
1. Open **Settings** → **Color**.
2. Select your Laptop Screen / Display.
3. Click **Add Profile** (if `Yoga14AKp10` isn't listed, select "Other profile..." and browse to `/usr/share/color/icc/colord/Yoga14AKp10.icm`).
4. Select `Yoga14AKp10.icm` and enable/activate it.

#### KDE Plasma
1. Open **System Settings** → **Display & Monitor** → **Color Management**.
2. Click **Add Profile** under your internal display panel.
3. Select `Yoga14AKp10` and set it as the default.

#### Other Environments (via command line / colord)
You can assign and activate the profile using the `colormgr` CLI tool:

1. Import the profile into `colord` database:
   ```bash
   colormgr import-profile /usr/share/color/icc/colord/Yoga14AKp10.icm
   ```
2. Find the Device ID of your monitor:
   ```bash
   colormgr get-devices
   ```
   *(Look for a device with Type: `display`, e.g. `xrandr-eDP-1` or similar)*
3. Find the Profile ID of your imported profile:
   ```bash
   colormgr get-profiles
   ```
4. Assign the profile to your device:
   ```bash
   colormgr device-add-profile <device_id> <profile_id>
   ```
5. Set it as default:
   ```bash
   colormgr device-make-profile-default <device_id> <profile_id>
   ```

---

## Current Wayland / Niri Status

As of mid-2026, **Niri does not natively support loading or applying custom ICC color profiles** through its configuration (`config.kdl`). Full Wayland color management protocols are actively in development upstream. 

If you run GNOME or KDE Plasma, the compositor will handle application of this profile automatically. For updates or workarounds on Niri, monitor [niri-wm/niri discussion #2458](https://github.com/niri-wm/niri/discussions/2458).
