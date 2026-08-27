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

# Dispatch to OS-specific installer
OS="$(uname -s)"
case "$OS" in
    Darwin)
        bash "$SCRIPT_SRC/install-macos.sh"
        ;;
    Linux)
        bash "$SCRIPT_SRC/install-linux.sh"
        ;;
    *)
        echo "Unsupported operating system: $OS (supported: macOS, Ubuntu/Linux)"
        exit 1
        ;;
esac
