# Transforming CachyOS to Pure Arch Linux

This guide details how to fully migrate away from CachyOS repositories if you decide to go back to a pure Arch setup for maximum longevity.

## Complete Migration to Pure Arch (The "Exit Strategy")

If you ever want to completely drop CachyOS and return to 100% upstream Arch Linux (e.g., if CachyOS stops being maintained):

**1. Remove the CachyOS Repositories**
Edit your pacman configuration:
```bash
sudo micro /etc/pacman.conf
```
Remove or comment out the `[cachyos]` repository blocks (and their `Include` lines) located above `[core]`.

**2. Refresh Pacman Databases**
```bash
sudo pacman -Syy
```
*(Your installed CachyOS packages are now considered "foreign" or local packages.)*

**3. Swap the Kernel and Clean up Bootloader**
Move back to the standard Arch kernel and remove the CachyOS kernel to prevent duplicate menu entries:
```bash
sudo pacman -S linux linux-headers
sudo pacman -Rs linux-cachyos linux-cachyos-headers
```
Clean up the CachyOS bootloader theme blocks from `/boot/limine.conf`:
```bash
sudo sed -i '/# CachyOS Limine theme/,/wallpaper:/d' /boot/limine.conf
sudo sed -i '/interface_branding:/d' /boot/limine.conf
sudo sed -i '/term_palette/d; /term_background/d; /term_foreground/d' /boot/limine.conf
```
Update your Limine configuration (usually `/etc/default/limine`) to ensure your kernel parameters (like `amd_pstate=active pcie_aspm=force`) are preserved for the new kernel, then regenerate the bootloader config:
```bash
sudo limine-mkinitcpio
sudo limine-update
```
*(Note: If a CachyOS entry still appears in the boot menu, you may need to manually remove its `ENTRY` block from `/boot/limine/limine.conf` and run `limine-update` again.)*

**4. Replace Scheduler Tools**
Install the official upstream versions of the schedulers from the Arch `extra` repository:
```bash
sudo pacman -S extra/scx-scheds extra/scx-tools
```
*(If you were using `scx-manager`, it will stop receiving updates as it is CachyOS-specific, but your `/etc/scx_loader.toml` will continue to work perfectly with the upstream `scx_loader`)*

**5. Clean Up Leftovers & Purge Branding**
Remove CachyOS-specific branding, mask configuration hooks to prevent future updates from restoring them, and reset system themes to default.

* **Step A: Purge packages and mask branding hooks**
  ```bash
  # 1. Identify foreign packages
  pacman -Qm

  # 2. Mask branding hooks (prevents CachyOS from overwriting system files on update)
  sudo mkdir -p /etc/libalpm/hooks/
  for hook in os-release.hook lsb-release.hook; do
    sudo ln -sf /dev/null "/etc/libalpm/hooks/$hook"
  done

  # 3. Restore stock filesystem identity files
  sudo pacman -S filesystem lsb-release
  sudo ln -sf /usr/lib/os-release /etc/os-release
  sudo ln -sf /usr/lib/lsb-release /etc/lsb-release
  ```

* **Step B: Reset GDM Login Screen Logo (Optional)**
  Choose depending on whether you want to keep other CachyOS performance tweaks:
  * **Option 1 (Full Purge):** Remove the settings packages:
    ```bash
    sudo pacman -Rs cachyos-hooks cachyos-settings cachyos-hello
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    ```
  * **Option 2 (Keep tweaks, hide logo):** Override the organization schema:
    ```bash
    printf '[org.gnome.login-screen]\nlogo='\'''\''\n' | sudo tee /usr/share/glib-2.0/schemas/zzzz_arch-fix.gschema.override
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    ```

* **Step C: Restore Plymouth Boot Splash Theme**
  ```bash
  sudo plymouth-set-default-theme bgrt
  sudo mkinitcpio -P
  sudo limine-update
  ```

