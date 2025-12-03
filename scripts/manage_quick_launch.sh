#!/bin/bash

CONFIG_FILE="$HOME/.config/sketchybar/quick_launch_apps.txt"

# Create config file if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

# Main menu
while true; do
    choice=$(osascript <<EOF
tell application "System Events"
    activate
    set dialogResult to choose from list {"Add Application", "Remove Application", "View Current Apps", "Exit"} with prompt "Quick Launch Manager" default items {"Add Application"}
    if dialogResult is false then
        return "Exit"
    else
        return item 1 of dialogResult
    end if
end tell
EOF
)

    case "$choice" in
        "Add Application")
            # Let user select an application
            app_path=$(osascript <<'EOF'
tell application "System Events"
    activate
    set appFile to choose file with prompt "Select an application to add:" of type {"com.apple.application-bundle"} default location (path to applications folder)
    return POSIX path of appFile
end tell
EOF
)

            if [ -n "$app_path" ]; then
                app_name=$(basename "$app_path" .app)

                # Check if already in list
                if grep -Fxq "$app_name" "$CONFIG_FILE" 2>/dev/null; then
                    osascript -e "display dialog \"$app_name is already in Quick Launch\" buttons {\"OK\"} default button 1 with icon caution"
                else
                    echo "$app_name" >> "$CONFIG_FILE"
                    sketchybar --reload
                    osascript -e "display notification \"$app_name added to Quick Launch\" with title \"Quick Launch\""
                fi
            fi
            ;;

        "Remove Application")
            # Get current apps
            if [ ! -s "$CONFIG_FILE" ]; then
                osascript -e 'display dialog "No applications in Quick Launch" buttons {"OK"} default button 1 with icon caution'
                continue
            fi

            # Read apps into array for AppleScript
            apps_list=$(cat "$CONFIG_FILE" | tr '\n' ',' | sed 's/,$//')

            app_to_remove=$(osascript <<EOF
tell application "System Events"
    activate
    set appList to {$apps_list}
    set dialogResult to choose from list appList with prompt "Select an application to remove:" default items {item 1 of appList}
    if dialogResult is false then
        return ""
    else
        return item 1 of dialogResult
    end if
end tell
EOF
)

            if [ -n "$app_to_remove" ]; then
                # Remove from config file
                grep -Fxv "$app_to_remove" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
                mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                sketchybar --reload
                osascript -e "display notification \"$app_to_remove removed from Quick Launch\" with title \"Quick Launch\""
            fi
            ;;

        "View Current Apps")
            if [ ! -s "$CONFIG_FILE" ]; then
                osascript -e 'display dialog "No applications in Quick Launch" buttons {"OK"} default button 1 with icon note'
            else
                apps_display=$(cat "$CONFIG_FILE" | sed 's/^/  • /' | tr '\n' '\r')
                osascript -e "display dialog \"Current Quick Launch apps:\r\r$apps_display\" buttons {\"OK\"} default button 1 with icon note"
            fi
            ;;

        "Exit"|*)
            exit 0
            ;;
    esac
done
