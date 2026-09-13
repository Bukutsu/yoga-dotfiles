# Speaker audio

Yoga 7 2-in-1 14AKP10 (83JR). Realtek ALC287, four speakers: two tweeters plus two woofers.

## Four speakers

The kernel already enables the woofers on this board. Check with:

```bash
amixer -c2 get 'Bass Speaker'
```

If the control is missing and bass is gone (after a reinstall or on an older kernel), apply the pin quirk:

```bash
echo 'options snd-hda-intel model=(null),alc287-yoga9-bass-spk-pin' | sudo tee /etc/modprobe.d/alc287.conf
sudo dracut -f # Fedora; on Arch run: sudo mkinitcpio -P
```

Reboot after. Card positions can vary, so confirm with `aplay -l` that the quirk lands on the ALC287 card.

## Presets

The presets come from Lenovo's own Windows tuning, not from hand EQ. The Dolby DAX3 XML for subsystem `17AA:391C` (in the [Realtek/Dolby driver](https://support.lenovo.com/us/en/downloads/ds573482-audio-driver-realtek-dolby-yoga-7-2-in-1-14akp10-yoga-7-2-in-1-16akp10)) was converted with [speaker-tuning-to-easyeffects](https://github.com/antoinecellerier/speaker-tuning-to-easyeffects). The old `Z16` impulse was a ThinkPad Z16 Gen 1 tuning and is gone.

- `Dolby-Laptop-Balanced` — the stock tuning, on autoload for the speakers.
- `Dolby-Laptop-Detailed`, `Dolby-Laptop-Warm` — same correction, voicing differs at 10% strength. Near-identical to Balanced.
- `Yoga_7_Daily` — Balanced plus gentle air and autogain on, target −14. Levels volume across tracks.
- `Yoga_7_Diamond_Beta` — Balanced plus +5 dB air shelf at 8 kHz. Bright.
- `Yoga_7_KH120_Neutral` — Balanced with the 2.5 kHz presence bell flattened.
- `Default` — empty, on autoload for the TP35 Pro DAC and as fallback.

Autoload maps the Yoga speaker to `Dolby-Laptop-Balanced` and the TP35 Pro to `Default`. In EasyEffects set the output fallback preset to `Default` so new devices land there. That setting lives in `~/.config/easyeffects/db/easyeffectsrc`, so copying presets alone does not set it.

## Gotchas

- Switching outputs with the EasyEffects window open can segfault it. Close the window first; headless switching is fine.
- The XML also holds tablet, tent, and stand tunings. Only laptop pose is converted. Ask for the rest if you use those poses.
- These are 2 W drivers behind limiters. `Daily` plus the desktop slider past 100% is the loudest sane setup. Louder than that is distortion, not sound.
