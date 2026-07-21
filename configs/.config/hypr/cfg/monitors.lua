-- Monitors: Niri positions are logical pixels; Hyprland uses the same layout.
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@120.000",
    position = "0x0",
    scale = 1.67,
    bitdepth = 10,
    cm = "srgb",
    vrr = 2,
})
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@240.000",
    position = "auto-right",
    scale = 1,
})
