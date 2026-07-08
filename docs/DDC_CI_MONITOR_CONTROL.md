# DDC/CI Monitor Control (Input Switching)

External monitor input switching via DDC/CI on this Yoga 7 (AMD Radeon 840M/860M).

## TL;DR

`ddcutil` can't access `/dev/i2c-*` because the existing udev rule matches class `0x030000` but AMD RDNA 3.5 reports `0x038000`.

**Fix (one-time):**

```fish
echo 'SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x038000", MODE="0666"' | sudo tee /etc/udev/rules.d/99-amdgpu-i2c-uaccess.rules
sudo udevadm control --reload-rules
sudo chmod 666 /dev/i2c-*
```

Log out & back in or reboot makes it permanent (`chmod` just gets it working now).

## The Problem

The ddcutil package ships a udev rule at `/lib/udev/rules.d/60-ddcutil-i2c.rules` that grants access to i2c devices tagged `0x030000` (VGA-compatible display controllers). This laptop's AMD Radeon 840M/860M reports class `0x038000` ("Other" display controller), so the rule doesn't match.

## Usage

```fish
# Check monitor capabilities
ddcutil detect

# Switch to DisplayPort
ddcutil setvcp 60 0x0f

# Switch to HDMI
ddcutil setvcp 60 0x11
```

- VCP `0x60` = input source
- `0x0f` = DisplayPort 1
- `0x11` = HDMI 1
- `0x10` = DVI 1

## Why Not `TAG+="uaccess"`

`uaccess` (via systemd-logind ACL) is the cleaner approach but only applies at session login. It requires a `sudo udevadm trigger` + logout cycle to test. `MODE="0666"` is simpler for a single-user laptop — no group management, survives reboot without relogin.

## Display-Switch Automation

For USB-switch KVM automation, see [`display-switch`](https://github.com/haimgel/display-switch). Config at `~/.config/display-switch/display-switch.ini`.
