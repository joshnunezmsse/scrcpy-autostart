#!/bin/bash

# --- CONFIGURATION ---
CONFIG_DIR="$HOME/.config/scrcpy-autostart"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_FILE="/tmp/scrcpy-trigger.log"
ERR_FILE="/tmp/scrcpy-trigger.err"
MAX_LOG_SIZE=1048576 # 1MB
LAST_SERIAL=""

find_binary() {
    if command -v "$1" >/dev/null 2>&1; then
        command -v "$1"
    elif [ -f "/opt/homebrew/bin/$1" ]; then
        echo "/opt/homebrew/bin/$1"
    elif [ -f "/usr/local/bin/$1" ]; then
        echo "/usr/local/bin/$1"
    elif [ "$1" == "adb" ] && [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        echo "$HOME/Library/Android/sdk/platform-tools/adb"
    else
        echo ""
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
    if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE")" -gt "$MAX_LOG_SIZE" ]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi

    AUTO_LAUNCH=$(grep "^AUTO_LAUNCH=" "$CONFIG_FILE" | cut -d'=' -f2)
    CUSTOM_ARGS=$(grep "^CUSTOM_ARGS=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')

    # Get full device info line for USB devices
    DEVICE_INFO=$($ADB_PATH devices -l | grep " usb:")
    CURRENT_SERIAL=$(echo "$DEVICE_INFO" | awk '{print $1}')
    
    # Extract model (e.g., model:Pixel_9a -> Pixel_9a)
    DEVICE_MODEL=$(echo "$DEVICE_INFO" | grep -o "model:[^ ]*" | cut -d: -f2 | tr '_' ' ')

    if [ -n "$CURRENT_SERIAL" ] && [ "$CURRENT_SERIAL" != "$LAST_SERIAL" ]; then
        # Use Serial as fallback if Model extraction fails
        DISPLAY_NAME=${DEVICE_MODEL:-$CURRENT_SERIAL}
        echo "$(date): USB Device $DISPLAY_NAME ($CURRENT_SERIAL) detected." >> "$LOG_FILE"
        
        LAUNCH_CMD="$SCRCPY_PATH -s $CURRENT_SERIAL $CUSTOM_ARGS --power-off-on-close"
        
        if [ "$AUTO_LAUNCH" = "true" ]; then
            $LAUNCH_CMD &
        else
            RESPONSE=$(osascript -e "display dialog \"Android device '$DISPLAY_NAME' detected. Control device from Mac?\" buttons {\"No\", \"Yes\"} default button \"Yes\" with icon caution")
            if [ "$RESPONSE" = "button returned:Yes" ]; then
                $LAUNCH_CMD &
            fi
        fi
        LAST_SERIAL="$CURRENT_SERIAL"
    fi

    [ -z "$CURRENT_SERIAL" ] && LAST_SERIAL=""
    sleep 3
done