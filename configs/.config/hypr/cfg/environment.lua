-- Environment and cursor.
for name, value in pairs({
    ELECTRON_OZONE_PLATFORM_HINT = "auto",
    QT_QPA_PLATFORM = "wayland",
    QT_QPA_PLATFORMTHEME = "gtk3",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    XCURSOR_THEME = "Breeze_Light",
    XCURSOR_SIZE = "24",
    HYPRCURSOR_SIZE = "24",
}) do
    hl.env(name, value)
end
