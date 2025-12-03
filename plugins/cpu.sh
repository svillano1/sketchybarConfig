#!/bin/bash

# Get CPU usage percentage (system-wide average across all cores)
CPU_PERCENT=$(top -l 2 -n 0 -F | grep "CPU usage" | tail -1 | awk '{print $3}' | sed 's/%//')

# Color coding based on CPU usage
if [ "$CPU_PERCENT" -gt 80 ]; then
  COLOR=0xffff3b30  # Red for high usage
elif [ "$CPU_PERCENT" -gt 50 ]; then
  COLOR=0xffff9500  # Orange for medium usage
else
  COLOR=0xff34c759  # Green for normal usage
fi

sketchybar --set "$NAME" \
  icon.background.image="$HOME/.config/sketchybar/icons/cpu-final.png" \
  icon.background.image.scale=0.5 \
  icon.background.image.drawing=on \
  icon.background.drawing=on \
  icon.background.color=0x00000000 \
  icon.padding_left=0 \
  icon.padding_right=0 \
  icon="" \
  label="$CPU_PERCENT%" \
  label.color="$COLOR"
