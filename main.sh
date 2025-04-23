#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up combined Bluetooth sink..."

# 1) Gather all Bluetooth sinks (PulseAudio & PipeWire)
mapfile -t sinks_arr < <(
  pactl list short sinks |
    awk '/bluez_sink|bluez_output/ {print $2}'
)
if [ "${#sinks_arr[@]}" -lt 2 ]; then
  echo "Error: Less than two Bluetooth sinks found. Aborting." >&2
  exit 1
fi
sinks=$(IFS=, ; echo "${sinks_arr[*]}")

# 2) Unload any existing bt_combined module
old_mod=$(pactl list short modules |
            awk '/module-combine-sink/ && /sink_name=bt_combined/ {print $1}')
if [ -n "$old_mod" ]; then
  pactl unload-module "$old_mod"
  echo "==> Unloaded old bt_combined module (ID: $old_mod)."
fi

# 3) Load a new combined-sink module
new_mod=$(pactl load-module module-combine-sink \
  sink_name=bt_combined \
  slaves="$sinks" \
  channels=2 \
  channel_map=front-left,front-right)
echo "==> Loaded new bt_combined module (ID: $new_mod) with sinks: $sinks"

# 4) Set bt_combined as the default sink
pactl set-default-sink bt_combined
echo "==> Default sink set to 'bt_combined'."

echo "==> Done."
