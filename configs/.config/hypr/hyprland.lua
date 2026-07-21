-- Hyprland 0.55+ Lua entry point. Keep the port split like the Niri config.
require("cfg.monitors")
require("cfg.environment")
require("cfg.settings")
require("cfg.animations")
require("cfg.autostart")
require("cfg.keybinds")
require("cfg.rules")

-- Shell integration: replace this with another shell module when needed.
require("cfg.noctalia")
