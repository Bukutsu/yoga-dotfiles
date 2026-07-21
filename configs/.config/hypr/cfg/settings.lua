-- Look and feel. Niri has no borders, shadows, blur, or compositor wallpaper.
hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 8,
        border_size = 0,
        resize_on_border = false,
        allow_tearing = false,
        layout = "scrolling",
    },
    decoration = {
        rounding = 20,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur = { enabled = false },
    },
    animations = { enabled = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        -- Hyprland has no per-window enable-vrr rule; this is the closest global equivalent.
        vrr = 1,
    },
    binds = {
        workspace_back_and_forth = true,
    },
    input = {
        kb_layout = "us,th",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = -0.75,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.66667,
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 0.4,
        explicit_column_widths = "0.33333,0.5,0.66667",
        wrap_focus = true,
        wrap_swapcol = true,
        direction = "right",
    },
})
