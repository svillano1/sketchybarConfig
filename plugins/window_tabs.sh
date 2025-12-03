#!/bin/bash

# Icon cache directory
ICON_CACHE="$HOME/.config/sketchybar/app_icons"
mkdir -p "$ICON_CACHE"

# Temp directory for state tracking
STATE_DIR="$HOME/.config/sketchybar/.tab_state"
mkdir -p "$STATE_DIR"

# Function to get app icon
get_app_icon() {
    local app_name="$1"
    local icon_path=""

    # Special case for Finder
    if [ "$app_name" = "Finder" ]; then
        echo "📁"
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
    local app_path=$(osascript -e "tell application \"System Events\" to get POSIX path of (file of process \"$app_name\")" 2>/dev/null)

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

    # If we still don't have an icon, return a default
    if [ -z "$icon_path" ]; then
        case "$app_name" in
            "Safari") echo "􀎾" ;;
            "Mail"|"Microsoft Outlook") echo "􀍕" ;;
            "Calendar") echo "􀉉" ;;
            "Messages") echo "􀌤" ;;
            "FaceTime") echo "􀌥" ;;
            "Music"|"Spotify") echo "􀑪" ;;
            "Photos") echo "􀌟" ;;
            "Notes") echo "􀉓" ;;
            "Reminders") echo "􀆅" ;;
            "Terminal"|"kitty"|"iTerm") echo "􀆔" ;;
            "System Settings"|"System Preferences") echo "􀍟" ;;
            "Xcode") echo "􀫅" ;;
            "Firefox"|"firefox") echo "🦊" ;;
            "Chrome"|"Google Chrome") echo "🌐" ;;
            "Slack") echo "💬" ;;
            "Discord") echo "🎮" ;;
            "Visual Studio Code"|"VS Code"|"Electron") echo "􀫶" ;;
            "1Password") echo "🔐" ;;
            "Docker") echo "🐳" ;;
            *"Teams"*|*"MSTeams"*) echo "👥" ;;
            *"VPN"*) echo "🔒" ;;
            *) echo "􀣺" ;;
        esac
    else
        echo "$icon_path"
    fi
}

# Get display bounds for filtering windows by screen
get_display_info() {
    system_profiler SPDisplaysDataType | grep -A 10 "Resolution:" | grep -E "Resolution:|UI" | \
    awk 'BEGIN {display=1} /Resolution:/ {print "DISPLAY_"display"_INFO"; display++}'
}

# Detect which display this bar instance is on
# SketchyBar sets DISPLAY environment variable starting from 0
CURRENT_DISPLAY=$((${DISPLAY:-0} + 1))

# Get current window data and focused app with position information
window_data=$(osascript <<APPLESCRIPT
tell application "System Events"
    set output to ""
    set focusedAppName to ""

    -- Get the focused application
    set frontApp to first application process whose frontmost is true
    set focusedAppName to name of frontApp

    -- Rename focused Electron apps
    if focusedAppName is "Electron" then
        try
            set appPath to POSIX path of (file of frontApp)
            if appPath contains "Visual Studio Code" then
                set focusedAppName to "VS Code"
            end if
        end try
    end if

    set output to "FOCUSED:" & focusedAppName & linefeed

    set appList to every application process whose background only is false
    repeat with appProc in appList
        set appName to name of appProc
        set originalAppName to appName

        -- Rename Electron apps to their actual names
        if appName is "Electron" then
            try
                set appPath to POSIX path of (file of appProc)
                if appPath contains "Visual Studio Code" then
                    set appName to "VS Code"
                end if
            end try
        end if

        try
            set appWindows to every window of appProc
            set windowCount to count of appWindows
            if windowCount > 0 then
                set windowNames to ""
                repeat with appWindow in appWindows
                    set windowName to name of appWindow
                    if windowNames is "" then
                        set windowNames to windowName
                    else
                        set windowNames to windowNames & "||" & windowName
                    end if
                end repeat
                set output to output & appName & "|" & originalAppName & "|" & windowCount & "|" & windowNames & linefeed
            end if
        end try
    end repeat
    return output
end tell
APPLESCRIPT
)

# Extract focused app name from the first line
focused_app=$(echo "$window_data" | grep "^FOCUSED:" | cut -d: -f2)
window_data=$(echo "$window_data" | grep -v "^FOCUSED:")

# Get existing tabs from SketchyBar
existing_tabs=$(sketchybar --query bar | grep '"window.tab\.[^.]*"' | grep -v '\.badge\|\.window\.' | sed 's/.*"window\.tab\.\([^"]*\)".*/\1/')

# Clear state directory for this run
rm -f "$STATE_DIR"/current_*

# Parse window data and save to state files
echo "$window_data" | while IFS='|' read -r app_name original_app_name window_count window_names; do
    [ -z "$app_name" ] && continue
    [ -z "$window_count" ] && continue

    app_id=$(echo "${app_name}" | md5 | cut -c1-8)
    echo "$app_name|$original_app_name|$window_count|$window_names" > "$STATE_DIR/current_${app_id}"
done

# Process each current app
for state_file in "$STATE_DIR"/current_*; do
    [ ! -f "$state_file" ] && continue

    app_id=$(basename "$state_file" | sed 's/^current_//')
    IFS='|' read -r app_name original_app_name window_count window_names < "$state_file"

    item_name="window.tab.${app_id}"

    # Check if tab already exists
    tab_exists=0
    echo "$existing_tabs" | grep -q "^${app_id}$" && tab_exists=1

    display_name="$app_name"
    if [ ${#display_name} -gt 20 ]; then
        display_name="${display_name:0:17}..."
    fi

    app_icon=$(get_app_icon "$app_name")

    # Determine background color based on focus
    if [ "$app_name" = "$focused_app" ]; then
        bg_color="0x88000000"  # Darker for focused app
    else
        bg_color="0x44ffffff"  # Normal color for unfocused apps
    fi

    if [ $tab_exists -eq 1 ]; then
        # Update existing tab - set background color
        sketchybar --set "$item_name" background.color="$bg_color"

        if [ "$window_count" -gt 1 ]; then
            case "$window_count" in
                2) badge="❷" ;;
                3) badge="❸" ;;
                4) badge="❹" ;;
                5) badge="❺" ;;
                6) badge="❻" ;;
                7) badge="❼" ;;
                8) badge="❽" ;;
                9) badge="❾" ;;
                *) badge="$window_count" ;;
            esac

            sketchybar --set "$item_name" \
                       label="$display_name  $badge" \
                       label.font="Formula1:Regular:12.0" \
                       padding_left=4 \
                       padding_right=4 \
                       icon.padding_left=42 \
                       icon.padding_right=14 \
                       label.padding_left=24 \
                       label.padding_right=56
        else
            sketchybar --set "$item_name" \
                       label="$display_name" \
                       label.font="Formula1:Regular:11.0" \
                       padding_left=4 \
                       padding_right=4 \
                       icon.padding_left=42 \
                       icon.padding_right=14 \
                       label.padding_left=24 \
                       label.padding_right=56
        fi

        # Update popup items
        sketchybar --remove "/window\.tab\.${app_id}\.window\..*/" 2>/dev/null

        if [ "$window_count" -gt 1 ]; then
            window_index=0
            echo "$window_names" | tr '||' '\n' | while read -r window_name; do
                popup_item="${item_name}.window.${window_index}"

                popup_label="$window_name"
                if [ ${#popup_label} -gt 40 ]; then
                    popup_label="${popup_label:0:37}..."
                fi

                escaped_app_name="${original_app_name//\'/\\\'}"
                escaped_window_name="${window_name//\'/\\\'}"

                click_script="osascript -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to set frontmost to true' -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to perform action \"AXRaise\" of (first window whose name is \"$escaped_window_name\")' && sketchybar --set $item_name popup.drawing=off"

                sketchybar --add item "$popup_item" popup."$item_name" \
                           --set "$popup_item" \
                           label="  $popup_label" \
                           icon="→" \
                           icon.color=0xffffffff \
                           label.color=0xffffffff \
                           background.color=0x44000000 \
                           background.corner_radius=4 \
                           padding_left=4 \
                           padding_right=4 \
                           click_script="$click_script"

                window_index=$((window_index + 1))
            done
        fi
    else
        # Create new tab
        if [[ "$app_icon" == *.png ]]; then
            sketchybar --add item "$item_name" left \
                       --set "$item_name" \
                       icon=" " \
                       icon.background.image="$app_icon" \
                       icon.background.drawing=on \
                       icon.background.image.scale=0.6 \
                       icon.background.image.corner_radius=4 \
                       label="$display_name" \
                       background.color="$bg_color" \
                       background.corner_radius=4 \
                       background.height=22 \
                       padding_left=4 \
                       padding_right=4 \
                       icon.padding_left=42 \
                       icon.padding_right=14 \
                       label.padding_left=24 \
                       label.padding_right=56 \
                       click_script="sketchybar --set $item_name popup.drawing=toggle"
        else
            sketchybar --add item "$item_name" left \
                       --set "$item_name" \
                       icon="$app_icon" \
                       icon.font="SF Pro:Semibold:14.0" \
                       icon.drawing=on \
                       label="$display_name" \
                       background.color="$bg_color" \
                       background.corner_radius=4 \
                       background.height=22 \
                       padding_left=4 \
                       padding_right=4 \
                       icon.padding_left=42 \
                       icon.padding_right=14 \
                       label.padding_left=24 \
                       label.padding_right=56 \
                       click_script="sketchybar --set $item_name popup.drawing=toggle"
        fi

        # Add badge and popup for multi-window apps
        if [ "$window_count" -gt 1 ]; then
            case "$window_count" in
                2) badge="❷" ;;
                3) badge="❸" ;;
                4) badge="❹" ;;
                5) badge="❺" ;;
                6) badge="❻" ;;
                7) badge="❼" ;;
                8) badge="❽" ;;
                9) badge="❾" ;;
                *) badge="$window_count" ;;
            esac

            sketchybar --set "$item_name" \
                       label="$display_name  $badge" \
                       label.font="Formula1:Regular:12.0"

            window_index=0
            echo "$window_names" | tr '||' '\n' | while read -r window_name; do
                popup_item="${item_name}.window.${window_index}"

                popup_label="$window_name"
                if [ ${#popup_label} -gt 40 ]; then
                    popup_label="${popup_label:0:37}..."
                fi

                escaped_app_name="${original_app_name//\'/\\\'}"
                escaped_window_name="${window_name//\'/\\\'}"

                click_script="osascript -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to set frontmost to true' -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to perform action \"AXRaise\" of (first window whose name is \"$escaped_window_name\")' && sketchybar --set $item_name popup.drawing=off"

                sketchybar --add item "$popup_item" popup."$item_name" \
                           --set "$popup_item" \
                           label="  $popup_label" \
                           icon="→" \
                           icon.color=0xffffffff \
                           label.color=0xffffffff \
                           background.color=0x44000000 \
                           background.corner_radius=4 \
                           padding_left=4 \
                           padding_right=4 \
                           click_script="$click_script"

                window_index=$((window_index + 1))
            done
        else
            # Single window - set click to focus directly
            window_name=$(echo "$window_names" | head -1)
            escaped_app_name="${original_app_name//\'/\\\'}"
            escaped_window_name="${window_name//\'/\\\'}"

            click_script="osascript -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to set frontmost to true' -e 'tell application \"System Events\" to tell process \"$escaped_app_name\" to perform action \"AXRaise\" of (first window whose name is \"$escaped_window_name\")'"

            sketchybar --set "$item_name" click_script="$click_script"
        fi
    fi
done

# Remove tabs for apps that no longer exist
echo "$existing_tabs" | while read -r app_id; do
    [ -z "$app_id" ] && continue
    if [ ! -f "$STATE_DIR/current_${app_id}" ]; then
        sketchybar --remove "window.tab.${app_id}"
    fi
done
