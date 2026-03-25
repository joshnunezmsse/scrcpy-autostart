![License](https://img.shields.io/github/license/joshnunezmsse/scrcpy-autostart)
![Issues](https://img.shields.io/github/issues/joshnunezmsse/scrcpy-autostart)
![Stars](https://img.shields.io/github/stars/joshnunezmsse/scrcpy-autostart?style=social)

# scrcpy-autostart

A lightweight macOS daemon that monitors for newly connected Android devices and automatically initiates a `scrcpy` session. This tool is designed for developers who want to streamline their workflow by instantly mirroring their device's screen upon connection.

## Installation

**Prerequisites:** Before installing, you must enable **Developer Options** and **USB Debugging** on your Android device. You will also need to authorize your Mac for debugging.

You can install this tool by running the following command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/joshnunezmsse/scrcpy-autostart/main/install.sh)"
```

This command will download and run the installer, which handles dependency checks and setup.

## How It Works

The installer sets up a background service that periodically checks for Android devices connected via USB. When a new device is detected, it will either launch `scrcpy` immediately or prompt you for confirmation, depending on your configuration.

## Dependencies

The core dependencies for this tool are:
- **`adb`**: The Android Debug Bridge, used to detect connected devices.
- **`scrcpy`**: The screen mirroring application.

The installer will automatically check for these dependencies. If they are not found, it will attempt to install them using Homebrew.

## Configuration

You can customize the tool's behavior by editing the settings file located at `~/.config/scrcpy-autostart/settings.conf`.

- `AUTO_LAUNCH`: Set to `true` to have `scrcpy` launch immediately upon device connection. Set to `false` (the default) to be prompted by a macOS dialog first.
- `CUSTOM_ARGS`: A space-separated list of additional arguments to pass to the `scrcpy` command.

## Uninstallation

To remove the tool and all its components, you can run the uninstaller script:

```bash
~/.config/scrcpy-autostart/uninstall.sh
```

## Installation from Cloned Repo

If you prefer to install from a local clone of the repository:

1. Clone the repository:
   ```bash
   git clone https://github.com/joshnunezmsse/scrcpy-autostart.git
   cd scrcpy-autostart
   ```
2. Run the installer:
   ```bash
   ./install.sh
   ```
