# Thai font fallback

This fixes websites and Chromium-based browsers falling back to `TH Sarabun` (or other document fonts) instead of modern sans-serif UI fonts when rendering Thai text in an English-locale context.

## Problem

`TH Sarabun` packages Latin characters and declares support for English (`lang: en`). Dedicated Thai UI fonts like `Noto Sans Thai` only declare support for Thai (`lang: th`).

When a page (such as Facebook) sets `<html lang="en">`, Fontconfig penalizes `Noto Sans Thai` for not supporting English. Fallback characters then go to `TH Sarabun`. Because `TH Sarabun` has a ~50% em consonant body designed for MS Word printing, Thai text renders noticeably smaller and thinner than surrounding UI text.

## Solution

The tracked [`99-thai-fallback.conf`](../configs/.config/fontconfig/conf.d/99-thai-fallback.conf) explicitly binds `Noto Sans Thai` as the strong fallback for generic `sans-serif`, `serif`, and `monospace` families.

Explicit requests for `TH SarabunPSK` or `TH Sarabun New` in documents or government websites remain unaffected.

## Install

```bash
mkdir -p ~/.config/fontconfig/conf.d
cp configs/.config/fontconfig/conf.d/99-thai-fallback.conf ~/.config/fontconfig/conf.d/
fc-cache -fv ~/.config/fontconfig/conf.d
```

Restart running browsers to load the updated cache.
