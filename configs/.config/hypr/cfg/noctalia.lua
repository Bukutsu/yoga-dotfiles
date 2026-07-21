-- Noctalia shell integration.
-- Replace require("cfg.noctalia") in hyprland.lua with another shell module to switch shells.

local mainMod = "SUPER"
local ipc = "noctalia msg "

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
end)

hl.window_rule({
    name = "noctalia-settings",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})

-- Core shell controls.
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ipc .. "power-cycle"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd(ipc .. "session logout"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(ipc .. "session shutdown"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(ipc .. "session lock-and-suspend"))
hl.bind("Print", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(ipc .. "screenshot-region"))

-- Media and hardware OSD.
local locked = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), locked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), locked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), locked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(ipc .. "mic-mute"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. "media toggle"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. "media previous"), locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. "media next"), locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), locked)
