# Copilot key remapping

The Yoga's Copilot key emits `Left Meta + Left Shift + F23`. The tracked
[`keyd` config](../configs/system/etc/keyd/default.conf) converts that chord to
`F24`, which the compositor binds like a normal key.

## Install

```bash
sudo install -Dm644 configs/system/etc/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd
```

Test the key with:

```bash
sudo keyd monitor
```

If it emits a different chord, inspect the keyboard with `evtest` and update
`/etc/keyd/default.conf`. Under KDE, also enable **Use F13–F24 as usual function
keys** in System Settings → Keyboard → Key Bindings → Advanced.

See [keyd](https://github.com/rvaiya/keyd) and
[KDE bug #502639](https://bugs.kde.org/show_bug.cgi?id=502639) for details.
