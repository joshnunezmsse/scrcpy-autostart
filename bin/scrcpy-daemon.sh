#!/bin/bash

# Keep-alive wrapper for the scrcpy trigger monitor.
#
# XDG autostart (.desktop) entries run once at session start and do NOT
# restart a process if it exits. This wrapper re-launches the trigger
# script in a loop to keep it alive.

OS="$(uname -s)"
case "$OS" in
    Darwin) APP_DIR="$HOME/Library/Application Support/scrcpy-autostart" ;;
    *)      APP_DIR="$HOME/.local/share/scrcpy-autostart" ;;
esac

TRIGGER="$APP_DIR/scrcpy-trigger.sh"
LOG_FILE="/tmp/scrcpy-trigger.log"
ERR_FILE="/tmp/scrcpy-trigger.err"

if [ ! -x "$TRIGGER" ]; then
    echo "$(date): Trigger script not found at $TRIGGER" >> "$ERR_FILE"
    exit 1
fi

while true; do
    "$TRIGGER" >> "$LOG_FILE" 2>> "$ERR_FILE"
    # Trigger exited (crash or missing binaries). Restart after a short delay.
    sleep 3
done
