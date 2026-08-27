#!/bin/bash

# --- CONFIGURATION ---
OS="$(uname -s)"   # "Darwin" on macOS, "Linux" on Ubuntu

case "$OS" in
    Darwin) APP_DIR="$HOME/Library/Application Support/scrcpy-autostart" ;;
    *)      APP_DIR="$HOME/.local/share/scrcpy-autostart" ;;
esac

CONFIG_DIR="$HOME/.config/scrcpy-autostart"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_FILE="/tmp/scrcpy-trigger.log"
ERR_FILE="/tmp/scrcpy-trigger.err"
MAX_LOG_SIZE=1048576 # 1MB
LAST_SERIAL=""

# --- HELPERS ---

file_size() {
    case "$OS" in
        Darwin) stat -f%z "$1" ;;
        *)      stat -c%s "$1" ;;
    esac
}

ask_user() {
    local display_name="$1"
    local msg="Android device '$display_name' detected. Control device from this computer?"

    case "$OS" in
        Darwin)
            local response
            if ! response=$(osascript -e "display dialog \"$msg\" buttons {\"No\", \"Yes\"} default button \"Yes\" with icon caution" 2>/dev/null); then
                echo "$(date): Dialog tool failed (no display?); treating as decline." >> "$LOG_FILE"
                return 1
            fi
            if [ "$response" = "button returned:Yes" ]; then
                return 0
            else
                echo "$(date): User declined via dialog." >> "$LOG_FILE"
                return 1
            fi
            ;;
        *)
            # Determine whether a display is available (X11 or Wayland).
            HAS_DISPLAY=0
            if [ -n "${DISPLAY:-}" ]; then
                HAS_DISPLAY=1
            elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
                HAS_DISPLAY=1
            elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
                HAS_DISPLAY=1
            fi

            # Without a display we cannot show a dialog; launch automatically.
            if [ "$HAS_DISPLAY" -eq 0 ]; then
                echo "$(date): No display available; cannot show dialog. Launching automatically." >> "$LOG_FILE"
                return 0
            fi

            # Check for GUI tools that require a display
            ZENITY_PATH=$(find_binary "zenity")
            KDIALOG_PATH=$(find_binary "kdialog")

            if [ -n "$ZENITY_PATH" ] && [ -x "$ZENITY_PATH" ]; then
                local zenity_err
                zenity_err=$(zenity --question --text="$msg" 2>&1 >/dev/null)
                local zenity_rc=$?
                if [ $zenity_rc -eq 0 ]; then
                    return 0
                elif [ -n "$zenity_err" ]; then
                    echo "$(date): Zenity failed to display dialog: $zenity_err. Launching automatically." >> "$LOG_FILE"
                    return 0
                else
                    echo "$(date): User declined via zenity." >> "$LOG_FILE"
                    return 1
                fi
            elif [ -n "$KDIALOG_PATH" ] && [ -x "$KDIALOG_PATH" ]; then
                local kdialog_err
                kdialog_err=$(kdialog --yesno "$msg" 2>&1 >/dev/null)
                local kdialog_rc=$?
                if [ $kdialog_rc -eq 0 ]; then
                    return 0
                elif [ -n "$kdialog_err" ]; then
                    echo "$(date): KDialog failed to display dialog: $kdialog_err. Launching automatically." >> "$LOG_FILE"
                    return 0
                else
                    echo "$(date): User declined via kdialog." >> "$LOG_FILE"
                    return 1
                fi
            else
                echo "$(date): No GUI dialog tool found (zenity/kdialog); launching automatically." >> "$LOG_FILE"
                return 0
            fi
            ;;
    esac
}

find_binary() {
    if command -v "$1" >/dev/null 2>&1; then
        command -v "$1"
    elif [ -f "/opt/homebrew/bin/$1" ]; then
        echo "/opt/homebrew/bin/$1"
    elif [ -f "/usr/local/bin/$1" ]; then
        echo "/usr/local/bin/$1"
    elif [ "$OS" = "Darwin" ]; then
        if [ "$1" == "adb" ] && [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
            echo "$HOME/Library/Android/sdk/platform-tools/adb"
        else
            echo ""
        fi
    else
        if [ -f "$HOME/.local/bin/$1" ]; then
            echo "$HOME/.local/bin/$1"
        elif [ "$1" == "adb" ] && [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
            echo "$HOME/Android/Sdk/platform-tools/adb"
        else
            echo ""
        fi
    fi
}

ADB_PATH=$(find_binary "adb")
SCRCPY_PATH=$(find_binary "scrcpy")

if [ -z "$ADB_PATH" ] || [ -z "$SCRCPY_PATH" ]; then
    echo "$(date): Required binaries not found." >> "$ERR_FILE"
    exit 1
fi

export ADB="$ADB_PATH"

while true; do
    if [ -f "$LOG_FILE" ] && [ "$(file_size "$LOG_FILE")" -gt "$MAX_LOG_SIZE" ]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi

    AUTO_LAUNCH=$(grep "^AUTO_LAUNCH=" "$CONFIG_FILE" | cut -d'=' -f2)
    CUSTOM_ARGS=$(grep "^CUSTOM_ARGS=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')

    # Get full device info line for USB devices
    DEVICE_INFO=$($ADB_PATH devices -l | grep " usb:")
    CURRENT_SERIAL=$(echo "$DEVICE_INFO" | awk '{print $1}')

    # Extract model (e.g., model:Pixel_9a -> Pixel_9a)
    DEVICE_MODEL=$(echo "$DEVICE_INFO" | grep -o "model:[^ ]*" | cut -d: -f2 | tr '_' ' ')

    if [ "$CURRENT_SERIAL" != "$LAST_SERIAL" ]; then
        # Handle Disconnect
        if [ -n "$LAST_SERIAL" ]; then
            echo "$(date): Device ($LAST_SERIAL) disconnected." >> "$LOG_FILE"
            if [ -x "$CONFIG_DIR/host_on_disconnect.sh" ]; then
                "$CONFIG_DIR/host_on_disconnect.sh" "$LAST_SERIAL" >> "$LOG_FILE" 2>&1 &
            fi
        fi

        # Handle Connect
        if [ -n "$CURRENT_SERIAL" ]; then
            # Use Serial as fallback if Model extraction fails
            DISPLAY_NAME=${DEVICE_MODEL:-$CURRENT_SERIAL}
            echo "$(date): USB Device $DISPLAY_NAME ($CURRENT_SERIAL) detected." >> "$LOG_FILE"

            LAUNCH_CMD="$SCRCPY_PATH -s $CURRENT_SERIAL $CUSTOM_ARGS"

            if [ "$AUTO_LAUNCH" = "true" ]; then
                if [ -x "$APP_DIR/on_connect_helper.sh" ]; then
                    "$APP_DIR/on_connect_helper.sh" "$CURRENT_SERIAL" >> "$LOG_FILE" 2>&1 &
                fi
                $LAUNCH_CMD &
            else
                if ask_user "$DISPLAY_NAME"; then
                    if [ -x "$APP_DIR/on_connect_helper.sh" ]; then
                        "$APP_DIR/on_connect_helper.sh" "$CURRENT_SERIAL" >> "$LOG_FILE" 2>&1 &
                    fi
                    $LAUNCH_CMD &
                fi
            fi
        fi
        LAST_SERIAL="$CURRENT_SERIAL"
    fi

    sleep 3
done
