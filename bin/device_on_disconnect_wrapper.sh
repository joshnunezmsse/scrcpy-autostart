#!/system/bin/sh
# This script runs ON THE ANDROID DEVICE.
# It waits for the scrcpy session to end, then performs cleanup.
set -x

USER_SCRIPT="/data/local/tmp/device_on_disconnect.sh"

is_scrcpy_running() {
    ps -ef 2>/dev/null | grep "[s]crcpy" >/dev/null 2>&1 || \
    ps -A 2>/dev/null | grep "[s]crcpy" >/dev/null 2>&1 || \
    ps 2>/dev/null | grep "[s]crcpy" >/dev/null 2>&1
}

# Give scrcpy up to 15 seconds to start
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if is_scrcpy_running; then
        log -t ScrcpyAutostart "scrcpy session detected. Entering wait for disconnect state..."
        break
    fi

    sleep 1
done

# Wait until scrcpy stops running
while is_scrcpy_running; do
    sleep 3
done

log -t ScrcpyAutostart "scrcpy session ended. Proceeding with cleanup."

if [ -f "$USER_SCRIPT" ]; then
    # Execute the user-defined disconnect script
    sh "$USER_SCRIPT"
    rm -- "$USER_SCRIPT"
fi

# Finally, remove this wrapper script from the device to clean up.
rm -- "$0"