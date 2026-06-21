# Copilot Key — Fix for KDE Plasma

**Date:** 2026-06-21  
**System:** Fedora 44 + KDE Plasma 6 + Wayland  
**Status:** Working

## Problem

The Copilot key on modern laptops (Lenovo Yoga, Surface, etc.) sends a hardware chord of `Left Meta + Left Shift + F23`. KDE Plasma's shortcut system silently drops the `F23` component from the combo, so pressing the Copilot key is seen as `Meta+Shift` only — making it impossible to bind via the GUI.

GNOME handles this correctly (sees it as `Meta+Shift+Touchpad Disable` and exposes it for remapping). KDE has a [long-standing bug](https://bugs.kde.org/show_bug.cgi?id=502639) with this specific three-key chord.

## Root Cause

Three layers of issues:

1. **Hardware**: The Copilot key physically sends `KEY_LEFTMETA` + `KEY_LEFTSHIFT` + `KEY_F23` as separate evdev events (not a single scancode).
2. **KDE kguiaddons** (≤ 6.17): Has a bug where `Meta+Shift+F23` is not recognized as a valid shortcut — the F23 is silently dropped. (KF 6.18 added partial awareness but doesn't fully fix it.)
3. **XKB** (xkeyboard-config ≥ 2.44): Maps `Super+Shift+F23` to `XF86Assistant`, which KDE also doesn't expose as a bindable key.

## Solution: `keyd` + KDE Custom Shortcut

Use [keyd](https://github.com/rvaiya/keyd) to catch the hardware chord at the evdev level (before XKB/KDE touch it) and translate it to a single clean keypress that KDE can bind.

### Architecture

```
Copilot key press
  → evdev: KEY_LEFTMETA + KEY_LEFTSHIFT + KEY_F23
  → keyd catches chord, translates to single F24
  → KDE sees F24 → launches Konsole (or any bound action)
```

### Step 1: Enable F13-F24 in KDE

Open **System Settings → Keyboard → Key Bindings** → click the **Advanced** button (top-right) → expand **Function Keys** → check **"Use F13-F24 as usual function keys"** → Apply.

This ensures KDE exposes F24 as a regular bindable key rather than mapping it to `XF86Launch7`.

### Step 2: Install keyd

```bash
# Fedora (from Terra repo)
sudo dnf install keyd

# Arch (from AUR)
yay -S keyd
# or
paru -S keyd
```

### Step 3: Create config

Create `/etc/keyd/default.conf`:

```ini
[ids]
*

[main]
leftmeta+leftshift+f23 = f24
```

This tells keyd: when you see the exact chord `Left Meta + Left Shift + F23` pressed together, emit a single `F24` keypress instead.

### Step 4: Enable and start keyd

```bash
sudo systemctl enable --now keyd
```

Verify it's running:

```bash
sudo journalctl -u keyd -n 10
```

You should see keyd start without errors and detect your keyboard.

### Step 5: Bind F24 in KDE

Open **System Settings → Keyboard → Key Bindings**:

1. Find **Konsole** in the list (or search for it)
2. Click the shortcut input for the action
3. Press **F24**
4. Click **Apply**

Alternatively, you can bind F24 to any other action: launch any app, run a custom command, window management, etc.

### Step 6: Test

Press the Copilot key. Konsole should open immediately with no side effects.

## Verification

Check that keyd is catching the chord correctly:

```bash
# Watch keyd's debug log
sudo keyd monitor
```

Press the Copilot key — you should see `leftmeta+leftshift+f23` being caught and remapped.

## Remapping to a Different Key

To map the Copilot key to something other than F24, edit `/etc/keyd/default.conf` and change `f24` to any key name:

```ini
[main]
leftmeta+leftshift+f23 = rightcontrol      # Restore the replaced right-Ctrl
leftmeta+leftshift+f23 = menu              # Context menu key
leftmeta+leftshift+f23 = leftmeta          # Treat as a plain Super key
leftmeta+leftshift+f23 = f13              # Use another unused F-key
```

Then restart keyd:

```bash
sudo systemctl restart keyd
```

## Troubleshooting

### Keyd not catching the chord

```bash
sudo keyd monitor
```

Press the Copilot key. If you don't see `leftmeta+leftshift+f23`, your keyboard may send a different scancode sequence. Check with:

```bash
sudo evtest
```

Select your keyboard device, press the Copilot key, and note the EV_KEY codes emitted.

### KDE still doesn't recognize F24

Ensure **"Use F13-F24 as usual function keys"** is enabled in KDE Keyboard → Key Bindings → Advanced → Function Keys. Without this, KDE internally maps F24 to `XF86Launch7` and won't show it in the shortcut picker.

### Conflicts with other shortcuts

If F24 conflicts with an existing shortcut, pick a different unused key (F13-F22, or a specific combo like `Ctrl+Alt+Esc`).

## References

- [KDE Bug #502639](https://bugs.kde.org/show_bug.cgi?id=502639) — Ability to remap Copilot key
- [KDE Discuss: How to get System Settings to recognize F23](https://discuss.kde.org/t/how-to-get-system-settings-to-recognize-the-f23-part-of-copilot-key-combo/38701)
- [keyd project](https://github.com/rvaiya/keyd)
- [xkeyboard-config MR !772](https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/merge_requests/772) — `Super+Shift+F23` → `XF86Assistant`
