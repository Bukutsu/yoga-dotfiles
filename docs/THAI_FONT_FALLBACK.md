# Thai font fallback

This config makes websites and Chromium-based browsers use modern sans-serif UI fonts for Thai text in an English-locale context, rather than falling back to `TH Sarabun` or other document fonts.

## Problem

`TH Sarabun` includes Latin characters and declares English support (`lang: en`). Dedicated Thai UI fonts such as `Noto Sans Thai` only declare Thai support (`lang: th`).

When a page such as Facebook sets `<html lang="en">`, Fontconfig penalizes `Noto Sans Thai` because it does not support English. Thai characters then fall back to `TH Sarabun`. Designed for MS Word printing, `TH Sarabun` has a consonant body of about 50% em, so the Thai text looks smaller and thinner than the surrounding UI text.

## Solution

The tracked [`99-thai-fallback.conf`](../configs/.config/fontconfig/conf.d/99-thai-fallback.conf) sets `Noto Sans Thai` as the strong fallback for the generic `sans-serif`, `serif`, and `monospace` families.

Documents and government websites that explicitly request `TH SarabunPSK` or `TH Sarabun New` still use those fonts.

## Install

```bash
mkdir -p ~/.config/fontconfig/conf.d
cp configs/.config/fontconfig/conf.d/99-thai-fallback.conf ~/.config/fontconfig/conf.d/
fc-cache -fv ~/.config/fontconfig/conf.d
```

Restart your browsers to load the updated cache.
