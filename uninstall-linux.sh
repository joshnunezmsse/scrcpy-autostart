#!/bin/bash

APP_DIR="$HOME/.local/share/scrcpy-autostart"
CONFIG_DIR="$HOME/.config/scrcpy-autostart"

echo "Uninstalling scrcpy-autostart..."

# 1. Stop and remove autostart entry
pkill -f "scrcpy-daemon.sh" 2>/dev/null || true
pkill -f "scrcpy-trigger.sh" 2>/dev/null || true
rm -f "$HOME/.config/autostart/scrcpy-autostart.desktop"

# 2. Clean up app files and logs
rm -rf "$APP_DIR"
rm -f /tmp/scrcpy-trigger.log /tmp/scrcpy-trigger.err

# 3. Clean up config and self
read -rp "Remove configuration files and this uninstaller? (y/n): " RM_ALL
if [[ "$RM_ALL" == "y" ]]; then
    rm -rf "$CONFIG_DIR"
    echo "✓ All files removed."
else
    echo "Configuration kept at $CONFIG_DIR"
fi
