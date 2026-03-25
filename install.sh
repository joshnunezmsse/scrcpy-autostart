#!/bin/bash

# Identify source directory
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"

# If required files are missing, assume remote install
if [ ! -f "$SCRIPT_SRC/bin/scrcpy-trigger.sh" ]; then
    echo "Starting remote installation..."
    TEMP_DIR=$(mktemp -d /tmp/scrcpy-autostart.XXXXXX)
    
    echo "Downloading repository to $TEMP_DIR..."
    curl -fsSL "https://github.com/joshnunezmsse/scrcpy-autostart/archive/refs/heads/main.zip" -o "$TEMP_DIR/scrcpy.zip"
    unzip -q "$TEMP_DIR/scrcpy.zip" -d "$TEMP_DIR"
    
    # Run the actual installer
    bash "$TEMP_DIR/scrcpy-autostart-main/install.sh"
    INSTALL_RESULT=$?
    
    # Clean up and exit
    rm -rf "$TEMP_DIR"
    exit $INSTALL_RESULT
fi

APP_DIR="$HOME/Library/Application Support/scrcpy-autostart"
CONFIG_DIR="$HOME/.config/scrcpy-autostart"
PLIST_NAME="com.user.scrcpy.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "Starting scrcpy-autostart installation..."

# Create directory structure
mkdir -p "$APP_DIR"
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$CONFIG_DIR"

# 0. Dependency Check (SDK-Aware)
find_existing_adb() {
    if command -v adb >/dev/null 2>&1; then echo "$(command -v adb)"
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

# 2. Setup Config
if [ ! -f "$CONFIG_DIR/settings.conf" ]; then
    cp "$SCRIPT_SRC/config/settings.conf" "$CONFIG_DIR/"
fi

# 3. Move Uninstall Script to Config folder
chmod +x "$SCRIPT_SRC/uninstall.sh"
cp "$SCRIPT_SRC/uninstall.sh" "$CONFIG_DIR/"

# 4. Configure and Load Plist
sed "s|/Users/REPLACE_WITH_USER|$HOME|g" "$SCRIPT_SRC/launchd/$PLIST_NAME" > "$PLIST_DEST"

echo "Registering background service..."
launchctl unload "$PLIST_DEST" 2>/dev/null
launchctl load "$PLIST_DEST"

echo "✓ Installation complete."
echo "Note: To uninstall, run: $CONFIG_DIR/uninstall.sh"