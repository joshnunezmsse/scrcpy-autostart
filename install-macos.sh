#!/bin/bash

# Identify source directory
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"

APP_DIR="$HOME/Library/Application Support/scrcpy-autostart"
CONFIG_DIR="$HOME/.config/scrcpy-autostart"
PLIST_NAME="com.user.scrcpy.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "Starting scrcpy-autostart installation..."

# Stop existing service and ensure old processes are dead to allow clean updates
launchctl unload "$PLIST_DEST" 2>/dev/null || true
pkill -f "scrcpy-trigger.sh" 2>/dev/null || true

# Create directory structure
mkdir -p "$APP_DIR"
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$CONFIG_DIR"

# 0. Dependency Check (SDK-Aware)
find_existing_adb() {
    if command -v adb >/dev/null 2>&1; then command -v adb
    elif [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then echo "$HOME/Library/Android/sdk/platform-tools/adb"
    else echo ""; fi
}

echo "Checking dependencies..."
ADB_PATH=$(find_existing_adb)
if [ -z "$ADB_PATH" ]; then
    echo "adb not found. Installing via Homebrew..."
    brew install --cask android-platform-tools
fi

if ! command -v scrcpy >/dev/null 2>&1; then
    echo "scrcpy not found. Installing via Homebrew..."
    brew install scrcpy
fi

# 1. Setup Binaries
xattr -d com.apple.quarantine "$SCRIPT_SRC/bin/scrcpy-trigger.sh" 2>/dev/null || true
chmod +x "$SCRIPT_SRC/bin/scrcpy-trigger.sh"
cp "$SCRIPT_SRC/bin/scrcpy-trigger.sh" "$APP_DIR/"

xattr -d com.apple.quarantine "$SCRIPT_SRC/bin/on_connect_helper.sh" 2>/dev/null || true
chmod +x "$SCRIPT_SRC/bin/on_connect_helper.sh"
cp "$SCRIPT_SRC/bin/on_connect_helper.sh" "$APP_DIR/"

xattr -d com.apple.quarantine "$SCRIPT_SRC/bin/device_on_disconnect_wrapper.sh" 2>/dev/null || true
chmod +x "$SCRIPT_SRC/bin/device_on_disconnect_wrapper.sh"
cp "$SCRIPT_SRC/bin/device_on_disconnect_wrapper.sh" "$APP_DIR/"

# 2. Setup Config
if [ ! -f "$CONFIG_DIR/settings.conf" ]; then
    cp "$SCRIPT_SRC/config/settings.conf" "$CONFIG_DIR/"
fi

# Deploy optional hook scripts if they exist in the repo
if [ -f "$SCRIPT_SRC/config/host_on_connect.sh" ]; then
    if [ ! -f "$CONFIG_DIR/host_on_connect.sh" ]; then
        cp "$SCRIPT_SRC/config/host_on_connect.sh" "$CONFIG_DIR/"
        chmod +x "$CONFIG_DIR/host_on_connect.sh"
    fi
fi

if [ -f "$SCRIPT_SRC/config/device_on_connect.sh" ]; then
    if [ ! -f "$CONFIG_DIR/device_on_connect.sh" ]; then
        cp "$SCRIPT_SRC/config/device_on_connect.sh" "$CONFIG_DIR/"
    fi
fi

if [ -f "$SCRIPT_SRC/config/host_on_disconnect.sh" ]; then
    if [ ! -f "$CONFIG_DIR/host_on_disconnect.sh" ]; then
        cp "$SCRIPT_SRC/config/host_on_disconnect.sh" "$CONFIG_DIR/"
        chmod +x "$CONFIG_DIR/host_on_disconnect.sh"
    fi
fi

if [ -f "$SCRIPT_SRC/config/device_on_disconnect.sh" ]; then
    if [ ! -f "$CONFIG_DIR/device_on_disconnect.sh" ]; then
        cp "$SCRIPT_SRC/config/device_on_disconnect.sh" "$CONFIG_DIR/"
    fi
fi

# 3. Move Uninstall Scripts to Config folder
chmod +x "$SCRIPT_SRC/uninstall.sh"
cp "$SCRIPT_SRC/uninstall.sh" "$CONFIG_DIR/"

chmod +x "$SCRIPT_SRC/uninstall-macos.sh"
cp "$SCRIPT_SRC/uninstall-macos.sh" "$CONFIG_DIR/"

chmod +x "$SCRIPT_SRC/uninstall-linux.sh"
cp "$SCRIPT_SRC/uninstall-linux.sh" "$CONFIG_DIR/"

# 4. Configure and Load Plist
sed "s|/Users/REPLACE_WITH_USER|$HOME|g" "$SCRIPT_SRC/launchd/$PLIST_NAME" > "$PLIST_DEST"

echo "Registering background service..."
launchctl unload "$PLIST_DEST" 2>/dev/null
launchctl load "$PLIST_DEST"

echo "✓ Installation complete."
echo "Note: To uninstall, run: $CONFIG_DIR/uninstall.sh"