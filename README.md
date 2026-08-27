![License](https://img.shields.io/github/license/joshnunezmsse/scrcpy-autostart)
![Issues](https://img.shields.io/github/issues/joshnunezmsse/scrcpy-autostart)
![Stars](https://img.shields.io/github/stars/joshnunezmsse/scrcpy-autostart?style=social)

# scrcpy-autostart

A lightweight background service for macOS and Ubuntu (Linux) that monitors for newly connected Android devices and automatically initiates a `scrcpy` session. This tool is designed for developers who want to streamline their workflow by instantly mirroring their device's screen upon connection.

## Installation

**Prerequisites:** Before installing, you must enable **Developer Options** and **USB Debugging** on your Android device. You will also need to authorize your computer for debugging.

You can install this tool by running the following command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/joshnunezmsse/scrcpy-autostart/main/install.sh)"
```

This command will download and run the installer, which handles dependency checks and setup. The script auto-detects your operating system (macOS or Ubuntu) and installs the appropriate components.

### macOS Prerequisites
- **Homebrew** (the installer will automatically install dependencies via `brew`)

### Ubuntu Prerequisites
- **apt** package manager (the installer will automatically install dependencies via `sudo apt-get`)
- Alternatively, you can manually install the required packages:
  ```bash
  sudo apt-get update && sudo apt-get install -y adb scrcpy zenity
  ```
- **USB permission note:** If `adb devices` does not list your device, you may need to add your user to the plugdev group:
  ```bash
  sudo usermod -aG plugdev $USER
  ```
  (You will need to log out and back in for this to take effect.)

## How It Works

The installer sets up a background service that periodically checks for Android devices connected via USB. When a new device is detected, it will either launch `scrcpy` immediately or prompt you for confirmation, depending on your configuration.

- **macOS:** Uses a `LaunchAgent` plist to manage the background service via `launchctl`.
- **Ubuntu:** Uses an XDG autostart entry (`~/.config/autostart/scrcpy-autostart.desktop`) to launch a keep-alive daemon (`scrcpy-daemon.sh`) at login. The daemon runs the monitor script (`scrcpy-trigger.sh`) in a loop, restarting it automatically if it exits.

## Dependencies

The core dependencies for this tool are:
- **`adb`**: The Android Debug Bridge, used to detect connected devices.
- **`scrcpy`**: The screen mirroring application.

The installer will automatically check for these dependencies and install them using the appropriate package manager:
- **macOS:** Homebrew (`brew`)
- **Ubuntu:** apt (`sudo apt-get install -y ...`)

## Configuration

You can customize the tool's behavior by editing the settings file located at `~/.config/scrcpy-autostart/settings.conf`.

- **`AUTO_LAUNCH`**: Set to `true` to have `scrcpy` launch immediately upon device connection. Set to `false` (the default) to be prompted by a system dialog first.
  - **macOS:** Uses the native macOS `display dialog` utility.
  - **Ubuntu:** Uses `zenity` if available, or `kdialog` as a fallback. If neither dialog tool is present (e.g., in headless environments), the tool will automatically launch `scrcpy` and log a note instead of blocking.
- `CUSTOM_ARGS`: A space-separated list of additional arguments to pass to the `scrcpy` command.

## Custom Hooks

`scrcpy-autostart` supports running custom scripts automatically when a device connects or disconnects. These scripts can run either on your computer or directly on the Android device, allowing you to fully automate your development or mirroring environment.

**Note:** Native `scrcpy` functionality should be preferred over writing device hooks whenever possible. Hooks are designed to fill the gap for more nuanced and custom on-device scenarios. For example, you wouldn't write a hook to turn off the device screen, since that is already a built-in feature of `scrcpy` (configurable via `CUSTOM_ARGS="--turn-screen-off"`).

Hook scripts are located in `~/.config/scrcpy-autostart/`:
- `host_on_connect.sh` - Runs on your computer when a device connects.
- `host_on_disconnect.sh` - Runs on your computer when a device disconnects.
- `device_on_connect.sh` - Executed on the Android device via `adb shell` upon connection (useful for enforcing auto-rotate lock, launching a specific app for testing, or enabling Do Not Disturb mode during presentations).
- `device_on_disconnect.sh` - Executed on the Android device when the `scrcpy` session ends.

**Example: `device_on_connect.sh`**
Here is an example of automatically launching a specific application for testing as soon as the device connects:

```shellscript
#!/system/bin/sh
# Launch a specific app for testing
am start -n com.example.app/.MainActivity
```

**Example: `device_on_disconnect.sh`**
Here is an example of displaying a native notification on the Android device when your computer closes the screen mirroring session:

```shellscript
#!/system/bin/sh
# Show a notification (works on Android 11+)
cmd notification post -t "Scrcpy" "scrcpy_status" "Device disconnected from your computer"
```

## Logs

If you encounter issues or want to verify the background service is running correctly, you can check the host log files:

- **Service Logs:** `/tmp/scrcpy-trigger.log`
- **Error Logs:** `/tmp/scrcpy-trigger.err`

For custom device hooks (`device_on_connect.sh` and `device_on_disconnect.sh`), output is written to the Android device's native logging system. You can view these logs using:

```bash
adb logcat -s ScrcpyAutostart
```


## Uninstallation

To remove the tool and all its components, you can run the uninstaller script:

```bash
~/.config/scrcpy-autostart/uninstall.sh
```

The script auto-detects your operating system (macOS or Ubuntu) and removes the appropriate components.

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
