# Audio Tuning for Lenovo Yoga 7

The Yoga 7's 4-speaker system (2 tweeters + 2 woofers) is fully supported on modern kernels. To enhance audio quality beyond the defaults, use EasyEffects to apply professional audio DSP presets.

---

## Option 1: Dolby Atmos (Windows-Style)

Uses convolver presets extracted from Lenovo's official Dolby DAX3 drivers. Provides spatial widening and acoustic correction.

**Installation:**
```bash
# Install EasyEffects
sudo pacman -S easyeffects

# Create directories
mkdir -p ~/.config/easyeffects/irs
mkdir -p ~/.config/easyeffects/output

# Copy Dolby presets and impulse responses
cp yoga-dotfiles/configs/audio/easyeffects_irs/Dolby-Dynamic-Balanced.irs ~/.config/easyeffects/irs/
cp yoga-dotfiles/configs/audio/easyeffects_presets/ThinkPad_Z16_Dolby/Z16-Dynamic-Balanced.json ~/.config/easyeffects/output/
```

**Load:**
1. Open EasyEffects
2. Menu → Preferences → Enable "Launch Service at System Startup"
3. Presets menu → Select `Z16-Dynamic-Balanced` → Load

**What it does:**
- Convolver (IRS): Replicates Dolby Atmos acoustic correction for this chassis
- Stereo Widening: Cinematic soundstage
- Targeted EQ: Frequency shaping from official drivers
- Loudness optimization: Safe maximum volume without clipping

---

## Option 2: Harman Target (Neutral/Audiophile)

Industry-standard flat response tuning using parametric EQ. No convolver; lightweight and precise.

**Installation:**
```bash
cp yoga-dotfiles/configs/audio/easyeffects_presets/Yoga_7_Harman_Target.json ~/.config/easyeffects/output/
```

**Load:**
1. Open EasyEffects
2. Presets menu → Select `Yoga_7_Harman_Target` → Load

**Features:**
- +4.5dB vocal presence (3kHz)
- +3.0dB bass warmth (105Hz)
- -2.0dB treble reduction (5.5kHz, removes tweeter harshness)
