#!/bin/bash

# Identify source directory
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"

APP_DIR="$HOME/.local/share/scrcpy-autostart"
CONFIG_DIR="$HOME/.config/scrcpy-autostart"
DESKTOP_NAME="scrcpy-autostart"
DESKTOP_DEST="$HOME/.config/autostart/$DESKTOP_NAME.desktop"

echo "Starting scrcpy-autostart installation..."

# Stop any running monitor (daemon + trigger) to allow clean updates
pkill -f "scrcpy-daemon.sh" 2>/dev/null || true
pkill -f "scrcpy-trigger.sh" 2>/dev/null || true

# Create directory structure
mkdir -p "$APP_DIR"
mkdir -p "$HOME/.config/autostart"
mkdir -p "$CONFIG_DIR"

# 0. Dependency Check (SDK-Aware)
find_existing_adb() {
    if command -v adb >/dev/null 2>&1; then command -v adb
    elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then echo "$HOME/Android/Sdk/platform-tools/adb"
    else echo ""; fi
}

# Return 0 if a graphical session is available (X11 or Wayland).
in_graphical_session() {
    [ -n "${DISPLAY:-}" ] && return 0
    [ -n "${WAYLAND_DISPLAY:-}" ] && return 0
    case "${XDG_SESSION_TYPE:-}" in x11|wayland) return 0 ;; esac
    return 1
}

echo "Checking dependencies..."
APT_PACKAGES=()

ADB_PATH=$(find_existing_adb)
if [ -z "$ADB_PATH" ]; then
    echo "adb not found. Will install via apt."
    APT_PACKAGES+=("adb")
fi

if ! command -v scrcpy >/dev/null 2>&1; then
    echo "scrcpy not found. Will install via apt."
    APT_PACKAGES+=("scrcpy")
fi

if ! command -v zenity >/dev/null 2>&1 && ! command -v kdialog >/dev/null 2>&1; then
    echo "No dialog tool (zenity/kdialog) found. Will install zenity via apt."
    APT_PACKAGES+=("zenity")
fi

if [ "${#APT_PACKAGES[@]}" -gt 0 ]; then
    sudo apt-get update -y
    if ! sudo apt-get install -y "${APT_PACKAGES[@]}"; then
        echo "warning: some dependencies could not be installed (the runtime script will fall back to auto-launch if no dialog tool is available)" >&2
    fi
fi

# 1. Setup Binaries
chmod +x "$SCRIPT_SRC/bin/scrcpy-daemon.sh"
cp "$SCRIPT_SRC/bin/scrcpy-daemon.sh" "$APP_DIR/"

chmod +x "$SCRIPT_SRC/bin/scrcpy-trigger.sh"
cp "$SCRIPT_SRC/bin/scrcpy-trigger.sh" "$APP_DIR/"

chmod +x "$SCRIPT_SRC/bin/on_connect_helper.sh"
cp "$SCRIPT_SRC/bin/on_connect_helper.sh" "$APP_DIR/"

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

# 4. Configure and Register Autostart (XDG .desktop)
# The desktop entry is launched by the session at login, which provides
# GUI access (DISPLAY / WAYLAND_DISPLAY) in the user's environment.
sed "s|__HOME__|$HOME|g" "$SCRIPT_SRC/autostart/$DESKTOP_NAME.desktop" > "$DESKTOP_DEST"

echo "Registering autostart entry..."
# No daemon to reload for XDG autostart; the entry is picked up at next login.
# If a desktop session is already running, start the daemon now for convenience.
if in_graphical_session; then
    nohup "$APP_DIR/scrcpy-daemon.sh" >/dev/null 2>&1 &
    echo "Started monitor for the current session (it will also autostart at login)."
else
    echo "No graphical session detected; the monitor will start at next login."
fi

echo "✓ Installation complete."
echo "Note: To uninstall, run: $CONFIG_DIR/uninstall.sh"
