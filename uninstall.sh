#!/bin/bash

PLIST_DEST="$HOME/Library/LaunchAgents/com.user.scrcpy.plist"
APP_DIR="$HOME/Library/Application Support/scrcpy-autostart"
CONFIG_DIR="$HOME/.config/scrcpy-autostart"

echo "Uninstalling scrcpy-autostart..."

# 1. Stop and remove service
launchctl unload "$PLIST_DEST" 2>/dev/null
rm -f "$PLIST_DEST"

# 2. Clean up app files and logs
rm -rf "$APP_DIR"
rm -f /tmp/scrcpy-trigger.log /tmp/scrcpy-trigger.err
pkill -f "scrcpy-trigger.sh"

# 3. Clean up config and self
read -p "Remove configuration files and this uninstaller? (y/n): " RM_ALL
if [[ "$RM_ALL" == "y" ]]; then
    rm -rf "$CONFIG_DIR"
    echo "✓ All files removed."
else
    echo "Configuration kept at $CONFIG_DIR"
fi