#!/bin/bash

DEVICE_SERIAL=$1
CONFIG_DIR="$HOME/.config/scrcpy-autostart"
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Wrapper to prevent individual failures from killing the script
execute_safely() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "Error: Command failed with exit code $status: $*" >&2
    fi
    return 0
}

if [ -z "$DEVICE_SERIAL" ]; then
    echo "Error: No device serial provided to on_connect_helper.sh" >&2
    exit 1
fi

# Fallback if ADB is somehow not exported
if [ -z "$ADB" ]; then
    export ADB="adb"
fi

echo "--- Starting connection helper for $DEVICE_SERIAL ---"

# 1. Execute Host-side connect script
if [ -x "$CONFIG_DIR/host_on_connect.sh" ]; then
    echo "Running host_on_connect.sh..."
    execute_safely "$CONFIG_DIR/host_on_connect.sh" "$DEVICE_SERIAL"
else
    echo "Skipping host_on_connect.sh: File not found or not executable."
fi

# 2. Push and execute Device-side connect script
DEVICE_SCRIPT="device_on_connect.sh"
DEVICE_SCRIPT_PATH="/data/local/tmp/$DEVICE_SCRIPT"

if [ -f "$CONFIG_DIR/$DEVICE_SCRIPT" ]; then
    echo "Deploying on-device script: $DEVICE_SCRIPT..."
    
    execute_safely "$ADB" -s "$DEVICE_SERIAL" push "$CONFIG_DIR/$DEVICE_SCRIPT" "$DEVICE_SCRIPT_PATH"
    execute_safely "$ADB" -s "$DEVICE_SERIAL" shell chmod +x "$DEVICE_SCRIPT_PATH"
    execute_safely "$ADB" -s "$DEVICE_SERIAL" shell "sh $DEVICE_SCRIPT_PATH"
    execute_safely "$ADB" -s "$DEVICE_SERIAL" shell "rm -f $DEVICE_SCRIPT_PATH"
else
    echo "Skipping $DEVICE_SCRIPT: File not found."
fi

# 3. Push and execute Device-side disconnect watcher script
DEVICE_DISCONNECT_WRAPPER="device_on_disconnect_wrapper.sh"
DEVICE_DISCONNECT_WRAPPER_PATH="/data/local/tmp/$DEVICE_DISCONNECT_WRAPPER"
DEVICE_DISCONNECT_SCRIPT="device_on_disconnect.sh"
DEVICE_DISCONNECT_SCRIPT_PATH="/data/local/tmp/$DEVICE_DISCONNECT_SCRIPT"

if [ -f "$CONFIG_DIR/$DEVICE_DISCONNECT_SCRIPT" ]; then
    if [ -f "$APP_DIR/$DEVICE_DISCONNECT_WRAPPER" ]; then
        echo "Deploying on-device disconnect watcher wrapper: $DEVICE_DISCONNECT_WRAPPER..."
        execute_safely "$ADB" -s "$DEVICE_SERIAL" push "$APP_DIR/$DEVICE_DISCONNECT_WRAPPER" "$DEVICE_DISCONNECT_WRAPPER_PATH"
        execute_safely "$ADB" -s "$DEVICE_SERIAL" shell chmod +x "$DEVICE_DISCONNECT_WRAPPER_PATH"
        
        echo "Deploying user's on-device disconnect script: $DEVICE_DISCONNECT_SCRIPT..."
        execute_safely "$ADB" -s "$DEVICE_SERIAL" push "$CONFIG_DIR/$DEVICE_DISCONNECT_SCRIPT" "$DEVICE_DISCONNECT_SCRIPT_PATH"
        execute_safely "$ADB" -s "$DEVICE_SERIAL" shell chmod +x "$DEVICE_DISCONNECT_SCRIPT_PATH"

        execute_safely "$ADB" -s "$DEVICE_SERIAL" shell "nohup sh $DEVICE_DISCONNECT_WRAPPER_PATH </dev/null >/dev/null 2>&1 &"
    else
        echo "Error: Wrapper script $DEVICE_DISCONNECT_WRAPPER not found in $APP_DIR" >&2
    fi
else
    echo "Skipping $DEVICE_DISCONNECT_SCRIPT: File not found."
fi

echo "--- Finished connection helper for $DEVICE_SERIAL ---"