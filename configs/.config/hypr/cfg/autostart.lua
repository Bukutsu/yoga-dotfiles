-- Start the same desktop services as Niri. Wait for SensorProxy before rotating.
hl.on("hyprland.start", function()
    hl.exec_cmd("wluma")
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
