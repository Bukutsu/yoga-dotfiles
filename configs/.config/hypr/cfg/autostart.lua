-- Start the same desktop services as Niri.
hl.on("hyprland.start", function()
    hl.exec_cmd("wluma")
    -- ponytail: clear stale KMS HDR metadata until Hyprland resets it on startup itself.
    hl.exec_cmd([=[sh -c '
        sleep 1
        modetest -M amdgpu -c 2>/dev/null \
          | sed -n "/HDR_OUTPUT_METADATA:/,/vrr_capable:/p" \
          | grep -Eq "^[[:space:]]+[[:xdigit:]]{32}$" \
          || exit 0
        hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@120.000\", position = \"0x0\", scale = 1.67, bitdepth = 10, cm = \"hdr\", vrr = 2 })"
        sleep 0.5
        hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@120.000\", position = \"0x0\", scale = 1.67, bitdepth = 10, cm = \"srgb\", vrr = 2 })"
    ']=])
    -- monitor-sensor supplies events; Lua eval replaces iio-hyprland's legacy keyword calls.
    hl.exec_cmd([[sh -c '
        while true; do
            stdbuf -oL monitor-sensor --accel 2>&1 | while IFS= read -r line; do
                case "$line" in
                    *"orientation: normal"*|*"orientation changed: normal"*) transform=0 ;;
                    *"orientation: left-up"*|*"orientation changed: left-up"*) transform=1 ;;
                    *"orientation: bottom-up"*|*"orientation changed: bottom-up"*) transform=2 ;;
                    *"orientation: right-up"*|*"orientation changed: right-up"*) transform=3 ;;
                    *) continue ;;
                esac
                hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@120.000\", position = \"0x0\", scale = 1.67, transform = $transform, bitdepth = 10, cm = \"srgb\", vrr = 2 })" >/dev/null
                hyprctl eval "hl.config({ input = { touchdevice = { transform = $transform }, tablet = { transform = $transform } } })" >/dev/null
            done
            sleep 1
        done
    ']])
end)

-- Hyprland keeps DPMS-disabled outputs across hotplug; no Niri-style re-enable loop is needed.
