#!/bin/bash

# Script to remove an app from Quick Launch
CONFIG_FILE="$HOME/.config/sketchybar/quick_launch_apps.txt"
APP_NAME="$1"

if [ -z "$APP_NAME" ]; then
    exit 1
fi

# Remove the app from the config file
if [ -f "$CONFIG_FILE" ]; then
    # Create a temporary file without the app
    grep -Fxv "$APP_NAME" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    # Reload SketchyBar
    sketchybar --reload

    osascript -e "display notification \"$APP_NAME removed from Quick Launch\" with title \"Quick Launch\""
fi
