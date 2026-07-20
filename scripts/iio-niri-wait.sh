#!/bin/sh
# Wait for iio-sensor-proxy accelerometer, then start iio-niri.
# SensorProxy can appear before the accelerometer is ready; retry for 30s.

for i in $(seq 30); do
    busctl --system get-property \
        net.hadess.SensorProxy \
        /net/hadess/SensorProxy \
        net.hadess.SensorProxy \
        HasAccelerometer 2>/dev/null \
      | grep -qx 'b true' \
      && exec iio-niri listen --monitor eDP-1

    sleep 1
done

echo 'iio-niri: accelerometer not found after 30s' >&2
