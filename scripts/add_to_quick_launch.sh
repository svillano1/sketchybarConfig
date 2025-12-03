#!/bin/bash

# Script to add an app to Quick Launch
CONFIG_FILE="$HOME/.config/sketchybar/quick_launch_apps.txt"

# Get the app name from the argument (should be full path to .app)
APP_PATH="$1"

if [ -z "$APP_PATH" ]; then
    osascript -e 'display notification "No application selected" with title "Quick Launch"'
    exit 1
fi

# Extract app name from the path (remove .app extension)
APP_NAME=$(basename "$APP_PATH" .app)

# Check if app is already in the list
if grep -Fxq "$APP_NAME" "$CONFIG_FILE" 2>/dev/null; then
    osascript -e "display notification \"$APP_NAME is already in Quick Launch\" with title \"Quick Launch\""
    exit 0
fi

# Create config file if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

# Add the app to the config file
echo "$APP_NAME" >> "$CONFIG_FILE"

# Reload SketchyBar
sketchybar --reload

osascript -e "display notification \"$APP_NAME added to Quick Launch\" with title \"Quick Launch\""
