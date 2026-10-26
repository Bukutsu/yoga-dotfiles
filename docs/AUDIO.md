# Speaker audio

The Yoga 7 2-in-1 14AKP10 (83JR) has four speakers: two tweeters and two woofers. Its Realtek ALC3306 codec identifies as ALC287.

## Four speakers

The kernel already enables the woofers on this board. To check:

```bash
amixer -c2 get 'Bass Speaker'
```

If the control is missing and you have no bass, apply the pin quirk below. This can happen after a reinstall or on an older kernel.

```bash
echo 'options snd-hda-intel model=(null),alc287-yoga9-bass-spk-pin' | sudo tee /etc/modprobe.d/alc287.conf
sudo dracut -f # Fedora; on Arch run: sudo mkinitcpio -P
```

Reboot after applying the quirk. Card positions can vary, so use `aplay -l` to confirm that it applies to the ALC287 card.

## Presets

The presets use Lenovo's Windows tuning rather than hand-tuned EQ. They were converted from the Dolby DAX3 XML for subsystem `17AA:391C` in the [Realtek/Dolby driver](https://support.lenovo.com/us/en/downloads/ds573482-audio-driver-realtek-dolby-yoga-7-2-in-1-14akp10-yoga-7-2-in-1-16akp10), using [speaker-tuning-to-easyeffects](https://github.com/antoinecellerier/speaker-tuning-to-easyeffects). The old `Z16` impulse used ThinkPad Z16 Gen 1 tuning and has been removed.

- `Dolby-Laptop-Balanced`: stock tuning, set to autoload for the internal speaker.
- `Dolby-Laptop-Detailed`, `Dolby-Laptop-Warm`: the same correction with different voicing at 10% strength. Both sound nearly identical to Balanced.
- `Yoga_7_Daily`: Balanced with gentle air and autogain enabled, targeting −14 dB to level the volume across tracks.
- `Yoga_7_Diamond_Beta`: Balanced with a +5 dB air shelf at 8 kHz. It sounds bright.
- `Yoga_7_KH120_Neutral`: Balanced with the 2.5 kHz presence bell flattened.
- `Default`: an empty preset used as the fallback for every output except the internal speaker.

Convolver autogain is enabled in all correction presets. It restores the level lost to the correction without changing the curve. The limiter chain that follows catches peaks.

Autoload applies `Dolby-Laptop-Balanced` only to the internal speaker. In EasyEffects, enable the output fallback and choose `Default` as its preset so all other outputs use it. These settings live in `~/.config/easyeffects/db/easyeffectsrc`; copying the presets alone does not configure the fallback.

Autoload files are named `<device>:<route>.json`. The `device-profile` field uses the PipeWire route *description* (`Speaker`), not its name (`[Out] Speaker`). Headphones plugged into the jack use a separate route (`Headphones`), so they get `Default`.

The fallback also requires `outputAutoloadingUsesFallback=true` under `[Window]` in the same file. This setting is off by default. You can enable it with the fallback toggle on the autoloading page.

## Limitations

- Switching outputs while the EasyEffects window is open can cause a segfault. Close the window first. Switching with the window closed is fine.
- The XML also contains tablet, tent, and stand tunings. Only the laptop tuning has been converted. The conversion script can generate the others with `--mode tablet`, `tent`, or `stand`.
- These are small laptop drivers with limiters. `Daily` with the desktop volume slider above 100% is the loudest sensible setup. Pushing it further only adds limiter distortion.
