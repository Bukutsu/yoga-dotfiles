# Copilot key remapping

The Yoga's Copilot key sends `Left Meta + Left Shift + F23`. The tracked
[`keyd` config](../configs/system/etc/keyd/default.conf) remaps that chord to
`F24` so the compositor can bind it like a normal key.

## Install

```bash
sudo install -Dm644 configs/system/etc/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd
```

To check what the key sends, run:

```bash
sudo keyd monitor
```

If the key sends a different chord, inspect the keyboard with `evtest` and update
`/etc/keyd/default.conf`. In KDE, also enable **Use F13–F24 as usual function
keys** under System Settings → Keyboard → Key Bindings → Advanced.

For more details, see [keyd](https://github.com/rvaiya/keyd) and
[KDE bug #502639](https://bugs.kde.org/show_bug.cgi?id=502639).
