-- Start the same desktop services as Niri. Wait for SensorProxy before rotating.
hl.on("hyprland.start", function()
    hl.exec_cmd("wluma")
    -- ponytail: clear stale KMS HDR metadata until Hyprland resets it on startup itself.
    hl.exec_cmd([=[sh -c '
        sleep 1
        modetest -M amdgpu -c 2>/dev/null \
          | sed -n "/HDR_OUTPUT_METADATA:/,/vrr_capable:/p" \
          | grep -Eq "^[[:space:]]+[[:xdigit:]]{32}$" \
          || exit 0
        hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@120.000\", position = \"0x0\", scale = 1.50, bitdepth = 10, cm = \"hdr\", vrr = 2 })"
        sleep 0.5
        hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@120.000\", position = \"0x0\", scale = 1.50, bitdepth = 10, cm = \"srgb\", vrr = 2 })"
    ']=])
    hl.exec_cmd([[sh -c '
        for i in $(seq 30); do
            busctl --system get-property \
                net.hadess.SensorProxy \
                /net/hadess/SensorProxy \
                net.hadess.SensorProxy \
                HasAccelerometer 2>/dev/null \
              | grep -qx 'b true' \
              && exec iio-hyprland '' eDP-1
            sleep 1
        done
        echo 'iio-hyprland: accelerometer not found after 30s' >&2
    ']])
end)

-- Hyprland keeps DPMS-disabled outputs across hotplug; no Niri-style re-enable loop is needed.
