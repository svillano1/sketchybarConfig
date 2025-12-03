# SketchyBar Configuration

A customized macOS menu bar replacement using SketchyBar with window tabs and quick launch functionality.

## Features

### Window Tabs
- **Dynamic application tabs** that show all open applications with windows
- **Focus highlighting** - darker background for the currently focused app
- **Window count badges** - visual indicators (❷, ❸, etc.) for apps with multiple windows
- **Click to focus** - single-window apps activate on click
- **Window popup menu** - multi-window apps show a popup menu to select specific windows
- **Auto-refresh** - tabs update automatically when apps launch, quit, or windows change
- **Display filtering** - only shows tabs for windows on the current display (displays 1 and 2)

### Quick Launch
- **Icon-only launcher** on the right side of the menu bar
- **Custom app list** - easily configurable list of frequently used applications
- **Smart icon extraction** - automatically extracts app icons or uses fallback emojis/SF Symbols
- **GUI management** - use `ql-manage` command to add/remove apps via dialog interface
- **Icon caching** - extracted icons are cached for performance

### Visual Customization
- **Transparent background** - fully transparent menu bar with blur effect
- **Custom spacing and padding** - optimized layout for visual balance
- **SF Symbols and emojis** - consistent iconography throughout
- **Formula1 font** - custom font for labels

## Requirements

- macOS
- [SketchyBar](https://github.com/FelixKratz/SketchyBar)
- [yabai](https://github.com/koekeishiya/yabai) (optional, for window management events)
- Formula1 font (or will fall back to system fonts)

## Installation

1. Install SketchyBar:
   ```bash
   brew install sketchybar
   ```

2. Clone or copy this configuration to `~/.config/sketchybar/`:
   ```bash
   cp -r /path/to/this/repo ~/.config/sketchybar/
   ```

3. Make scripts executable:
   ```bash
   chmod +x ~/.config/sketchybar/plugins/*.sh
   chmod +x ~/.config/sketchybar/scripts/*.sh
   ```

4. Add the `ql-manage` alias to your `~/.zshrc`:
   ```bash
   alias ql-manage="$HOME/.config/sketchybar/scripts/manage_quick_launch.sh"
   ```

5. Start SketchyBar:
   ```bash
   brew services start sketchybar
   ```

## Configuration Structure

```
~/.config/sketchybar/
├── sketchybarrc              # Main configuration file
├── quick_launch_apps.txt     # Quick Launch app list
├── plugins/
│   ├── window_tabs.sh        # Window tabs plugin
│   ├── quick_launch.sh       # Quick Launch plugin
│   ├── battery.sh            # Battery indicator
│   ├── clock.sh              # Clock display
│   ├── cpu.sh                # CPU usage
│   ├── memory.sh             # Memory usage
│   └── space.sh              # Space indicators
├── scripts/
│   ├── manage_quick_launch.sh       # GUI manager for Quick Launch
│   ├── add_to_quick_launch.sh       # Add app to Quick Launch
│   └── remove_from_quick_launch.sh  # Remove app from Quick Launch
├── app_icons/                # Cached app icons (auto-generated)
└── .tab_state/              # Window tab state (auto-generated)
```

## Customization

### Bar Appearance

Edit `sketchybarrc` to customize the bar:

```bash
# Transparency (0x00000000 = fully transparent, 0xFF000000 = opaque black)
sketchybar --bar color=0x00000000

# Height and blur
sketchybar --bar height=28 blur_radius=30

# Display selection (show on displays 1 and 2 only)
sketchybar --bar display=1,2
```

### Quick Launch Apps

**Method 1: GUI Manager (Recommended)**
```bash
ql-manage
```
This opens a dialog where you can:
- Add applications via file picker
- Remove applications from the list
- View current apps

**Method 2: Edit config file**

Edit `quick_launch_apps.txt` and add one app name per line:
```
Google Chrome
Firefox
Finder
kitty
Notion
Slack
```

After editing, reload SketchyBar:
```bash
sketchybar --reload
```

### Window Tabs

Window tabs are automatically managed based on open applications. Customization options in `plugins/window_tabs.sh`:

- **Colors**: Modify `bg_color` for focused/unfocused states (lines 208-212)
- **Fonts**: Change label fonts (lines 233, 240)
- **Padding**: Adjust spacing (lines 234-243, 293-298, 312-315)
- **Badge style**: Modify window count indicators (lines 220-229)

### Custom Icons

Add custom icons for specific apps by editing the `get_app_icon()` function in `plugins/quick_launch.sh` or `plugins/window_tabs.sh`:

```bash
case "$app_name" in
    "Your App Name") echo "🎨" ;;  # Add your emoji or SF Symbol
    *) echo "􀣺" ;;  # Default icon
esac
```

## Item Descriptions

### Left Side
- **Space indicators** (1-10) - Mission Control spaces with click-to-switch
- **Window tabs** - Dynamic application tabs with focus highlighting

### Right Side
- **Quick Launch** - Icon-only app launcher
- **CPU usage** - Updates every 5 seconds
- **Memory usage** - Updates every 10 seconds
- **Battery** - Updates every 120 seconds or on power events
- **Clock** - Updates every second

## Events and Updates

The configuration subscribes to various system events:

- `front_app_switched` - Updates tab focus when switching apps
- `space_change` - Refreshes tabs when changing spaces
- `window_focus` - Updates when window focus changes
- `window_created` / `window_destroyed` - Updates when windows open/close
- `application_launched` / `application_terminated` - Updates when apps start/quit
- `system_woke` - Refreshes battery on wake
- `power_source_change` - Updates battery when power source changes

## Troubleshooting

### SketchyBar not appearing
```bash
# Check if SketchyBar is running
ps aux | grep sketchybar

# Restart SketchyBar
brew services restart sketchybar
```

### Tabs not updating
```bash
# Check for errors in the plugin
~/.config/sketchybar/plugins/window_tabs.sh

# Reload configuration
sketchybar --reload
```

### Icons not showing
- Check that apps are installed and accessible
- Clear icon cache: `rm -rf ~/.config/sketchybar/app_icons/`
- Reload: `sketchybar --reload`

### Quick Launch management
```bash
# If ql-manage doesn't work, run directly:
~/.config/sketchybar/scripts/manage_quick_launch.sh
```

## Performance Notes

- **Icon caching**: App icons are extracted once and cached in `app_icons/`
- **State tracking**: Window states are tracked in `.tab_state/` for efficient updates
- **Event-driven**: Updates only occur on relevant system events, not constant polling

## Credits

- [SketchyBar](https://github.com/FelixKratz/SketchyBar) by Felix Kratz
- Configuration inspired by the SketchyBar community
- Window management enhanced with macOS System Events and AppleScript

## License

This configuration is free to use and modify for personal use.
