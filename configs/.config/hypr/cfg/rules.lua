-- Window rules. Shell-specific rules live in cfg/noctalia.lua.
hl.window_rule({
    name = "steam-non-client-floating",
    match = { class = "(?i)^steam$" },
    float = true,
})
hl.window_rule({
    name = "steam-client-tiled",
    match = { class = "(?i)^steam$", title = "^[Ss]team$" },
    float = false,
})
hl.window_rule({
    name = "steam-notification-toast",
    match = { class = "(?i)^steam$", title = "^notificationtoasts_%d+_desktop$" },
    float = true,
    move = "monitor_w-window_w-10 monitor_h-window_h-10",
    no_focus = true,
})
hl.window_rule({
    name = "satty-floating",
    match = { class = "(?i)^satty$" },
    float = true,
})
