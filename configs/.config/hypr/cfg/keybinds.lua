local mainMod = "SUPER"
local terminal = "kitty"
local browser = "zen-browser"
local fileManager = "thunar"

local function bind(key, dispatcher, flags)
    hl.bind(mainMod .. " + " .. key, dispatcher, flags)
end

-- Focus and move. Scrolling's layout messages preserve Niri's column semantics.
for _, key in ipairs({ "left", "h" }) do
    bind(key, hl.dsp.layout("focus l"))
end
for _, key in ipairs({ "right", "l" }) do
    bind(key, hl.dsp.layout("focus r"))
end
for _, key in ipairs({ "up", "k" }) do
    bind(key, hl.dsp.focus({ direction = "up" }))
end
for _, key in ipairs({ "down", "j" }) do
    bind(key, hl.dsp.focus({ direction = "down" }))
end
for _, key in ipairs({ "left", "h" }) do
    bind("SHIFT + " .. key, hl.dsp.layout("swapcol l"))
end
for _, key in ipairs({ "right", "l" }) do
    bind("SHIFT + " .. key, hl.dsp.layout("swapcol r"))
end
for _, key in ipairs({ "up", "k" }) do
    bind("SHIFT + " .. key, hl.dsp.window.move({ direction = "up" }))
end
for _, key in ipairs({ "down", "j" }) do
    bind("SHIFT + " .. key, hl.dsp.window.move({ direction = "down" }))
end

-- Workspaces.
for i = 1, 9 do
    bind(tostring(i), hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
bind("0", hl.dsp.focus({ workspace = "previous" }))

for _, item in ipairs({
    { key = "left",  workspace = "e-1" },
    { key = "up",    workspace = "e-1" },
    { key = "right", workspace = "e+1" },
    { key = "down",  workspace = "e+1" },
    { key = "h",     workspace = "e-1" },
    { key = "k",     workspace = "e-1" },
    { key = "l",     workspace = "e+1" },
    { key = "j",     workspace = "e+1" },
}) do
    bind("CTRL + " .. item.key, hl.dsp.focus({ workspace = item.workspace }))
    bind("CTRL + SHIFT + " .. item.key, hl.dsp.window.move({ workspace = item.workspace }))
end

-- Monitors.
for _, item in ipairs({
    { key = "left",  direction = "l" }, { key = "h", direction = "l" },
    { key = "right", direction = "r" }, { key = "l", direction = "r" },
    { key = "up",    direction = "u" }, { key = "k", direction = "u" },
    { key = "down",  direction = "d" }, { key = "j", direction = "d" },
}) do
    bind("ALT + " .. item.key, hl.dsp.focus({ monitor = item.direction }))
    bind("ALT + SHIFT + " .. item.key, hl.dsp.workspace.move({ monitor = item.direction }))
end
bind("ALT + I", hl.dsp.dpms({ action = "toggle", monitor = "eDP-1" }))

-- iio-hyprland has no rotation-lock IPC; pause/resume the daemon instead.
bind("O", hl.dsp.exec_cmd("if ps -C iio-hyprland -o stat= | grep -q '^T'; then pkill -CONT -x iio-hyprland; else pkill -STOP -x iio-hyprland; fi"))

-- Windows and scrolling layout operations.
bind("Q", hl.dsp.window.close())
bind("ALT + ESCAPE", hl.dsp.window.close())
bind("M", hl.dsp.layout("fit expand"))
bind("F11", hl.dsp.window.fullscreen({ action = "toggle", layout_aware = true }))
bind("G", hl.dsp.window.float({ action = "toggle" }))
bind("Y", hl.dsp.window.float({ action = "toggle" }))
bind("S", hl.dsp.layout("consume_or_expel prev"))
bind("X", hl.dsp.layout("swapcol r"))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = false }))
bind("Tab", hl.dsp.window.cycle_next({ next = false }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = true }))
bind("SHIFT + Tab", hl.dsp.window.cycle_next({ next = true }))
bind("R", hl.dsp.layout("colresize +conf"))
bind("SHIFT + R", hl.dsp.layout("colresize -conf"))
bind("Equal", hl.dsp.layout("colresize +0.1"))
bind("Period", hl.dsp.layout("colresize +0.1"))
bind("Minus", hl.dsp.layout("colresize -0.1"))
bind("Comma", hl.dsp.layout("colresize -0.1"))

-- Applications and shell-independent fallbacks.
bind("T", hl.dsp.exec_cmd(terminal))
bind("RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("F24", hl.dsp.exec_cmd(terminal))
bind("F", hl.dsp.exec_cmd(fileManager))
bind("B", hl.dsp.exec_cmd(browser))
bind("ALT + S", hl.dsp.exec_cmd("orca"))
-- switch-layout "next" in Niri switches the keyboard layout.
bind("SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))