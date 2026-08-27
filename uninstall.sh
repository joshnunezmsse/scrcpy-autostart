#!/bin/bash

# Dispatcher: locate and execute OS-specific uninstall script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"

case "$(uname -s)" in
    Darwin)
        if [ -f "$SCRIPT_DIR/uninstall-macos.sh" ]; then
            exec bash "$SCRIPT_DIR/uninstall-macos.sh"
        else
            echo "error: uninstall-macos.sh not found in $(pwd)" >&2
            exit 1
        fi
        ;;
    Linux)
        if [ -f "$SCRIPT_DIR/uninstall-linux.sh" ]; then
            exec bash "$SCRIPT_DIR/uninstall-linux.sh"
        else
            echo "error: uninstall-linux.sh not found in $(pwd)" >&2
            exit 1
        fi
        ;;
    *)
        echo "error: unsupported OS $(uname -s)" >&2
        exit 1
        ;;
esac
