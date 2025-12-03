#!/bin/bash

# Get memory usage
MEMORY_STATS=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);')

# Calculate used memory percentage
MEMORY_USED=$(echo "$MEMORY_STATS" | awk '/active/ || /wired/ || /occupied/ {sum += $2} END {printf "%.0f", sum}')
MEMORY_TOTAL=$(sysctl -n hw.memsize | awk '{printf "%.0f", $0 / 1048576}')
MEMORY_PERCENT=$(echo "scale=2; ($MEMORY_USED / $MEMORY_TOTAL) * 100" | bc | awk '{printf "%.0f", $0}')

# Color coding based on memory usage
if [ "$MEMORY_PERCENT" -gt 80 ]; then
  COLOR=0xffff3b30  # Red for high usage
elif [ "$MEMORY_PERCENT" -gt 60 ]; then
  COLOR=0xffff9500  # Orange for medium usage
else
  COLOR=0xff34c759  # Green for normal usage
fi

sketchybar --set "$NAME" \
  icon=🧠 \
  label="$MEMORY_PERCENT%" \
  icon.color="$COLOR" \
  label.color="$COLOR"
