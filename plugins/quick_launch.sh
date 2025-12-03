#!/bin/bash

# Icon cache directory
ICON_CACHE="$HOME/.config/sketchybar/app_icons"
mkdir -p "$ICON_CACHE"

# Config file for Quick Launch apps
CONFIG_FILE="$HOME/.config/sketchybar/quick_launch_apps.txt"

# Read applications from config file
QUICK_LAUNCH_APPS=()
if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r app_name; do
        [ -z "$app_name" ] && continue  # Skip empty lines
        QUICK_LAUNCH_APPS+=("$app_name")
    done < "$CONFIG_FILE"
fi

# Function to get app icon (same as window_tabs.sh)
get_app_icon() {
    local app_name="$1"
    local icon_path=""

    # Special case for Finder
    if [ "$app_name" = "Finder" ]; then
        echo "🔍"
        return
    fi

    # Create a cache filename
    local cache_name=$(echo "$app_name" | sed 's/[^a-zA-Z0-9]/_/g')
    local cached_icon="$ICON_CACHE/${cache_name}.png"

    # Check if we have a cached icon
    if [ -f "$cached_icon" ]; then
        echo "$cached_icon"
        return
    fi

    # Try to get the app bundle path
    local app_path=$(mdfind "kMDItemKind == 'Application' && kMDItemFSName == '$app_name.app'" | head -1)

    if [ -n "$app_path" ]; then
        # Get the icon file from the app bundle
        local icon_file=$(defaults read "${app_path}/Contents/Info.plist" CFBundleIconFile 2>/dev/null)

        if [ -n "$icon_file" ]; then
            # Remove .icns extension if it exists
            icon_file="${icon_file%.icns}"
            local icns_path="${app_path}/Contents/Resources/${icon_file}.icns"

            # Try alternative icon locations
            if [ ! -f "$icns_path" ]; then
                icns_path="${app_path}/Contents/Resources/AppIcon.icns"
            fi

            # Convert .icns to PNG if found
            if [ -f "$icns_path" ]; then
                sips -s format png "$icns_path" --out "$cached_icon" --resampleWidth 32 >/dev/null 2>&1

                if [ -f "$cached_icon" ]; then
                    icon_path="$cached_icon"
                fi
            fi
        fi
    fi

    # If we still don't have an icon, return a default based on app name
    if [ -z "$icon_path" ]; then
        case "$app_name" in
            "Google Chrome"|"Chrome") echo "🌐" ;;
            "Firefox") echo "🦊" ;;
            "Finder") echo "📁" ;;
            "kitty"|"Terminal"|"iTerm") echo "􀆔" ;;
            "Notion") echo "􀉓" ;;
            "Slack") echo "💬" ;;
            "1Password") echo "🔐" ;;
            "Tailscale") echo "🔒" ;;
            *) echo "􀣺" ;;
        esac
    else
        echo "$icon_path"
    fi
}

# Create Quick Launch items
for app_name in "${QUICK_LAUNCH_APPS[@]}"; do
    # Create a unique ID for this app
    app_id=$(echo "$app_name" | md5 | cut -c1-8)
    item_name="quick_launch.${app_id}"

    # Get the app icon
    app_icon=$(get_app_icon "$app_name")

    # Escape app name for the launch script
    escaped_app_name="${app_name//\'/\\\\\'}"

    # Script paths
    REMOVE_SCRIPT="$HOME/.config/sketchybar/scripts/remove_from_quick_launch.sh"

    # Set font size based on app
    icon_font_size="20.0"
    if [ "$app_name" = "Finder" ]; then
        icon_font_size="13.0"
    fi

    # Create the Quick Launch item
    if [[ "$app_icon" == *.png ]]; then
        sketchybar --add item "$item_name" right \
                   --set "$item_name" \
                   icon=" " \
                   icon.background.image="$app_icon" \
                   icon.background.drawing=on \
                   icon.background.image.scale=0.65 \
                   icon.background.image.corner_radius=4 \
                   label.drawing=off \
                   background.drawing=off \
                   padding_left=3 \
                   padding_right=3 \
                   icon.padding_left=6 \
                   icon.padding_right=6 \
                   click_script="open -a '$escaped_app_name'"
    else
        sketchybar --add item "$item_name" right \
                   --set "$item_name" \
                   icon="$app_icon" \
                   icon.font="SF Pro:Semibold:${icon_font_size}" \
                   label.drawing=off \
                   background.drawing=off \
                   padding_left=3 \
                   padding_right=3 \
                   icon.padding_left=6 \
                   icon.padding_right=6 \
                   click_script="open -a '$escaped_app_name'"
    fi
done
