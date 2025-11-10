# Copy GIF - Native Messaging Host

This native messaging host enables the Copy GIF extension to copy **animated GIFs** to your clipboard, preserving the animation.

## Why is this needed?

The standard browser Clipboard API doesn't support animated GIFs on any platform (macOS, Windows, or Linux). Without this native host, the extension can only copy the first frame of a GIF as a PNG image.

With the native host installed, you can copy fully animated GIFs!

## Requirements

- **Python 3** (already installed on most systems)
- **macOS**: No additional requirements
- **Windows**: No additional requirements (uses PowerShell)
- **Linux**: Install `xclip` or `wl-copy`:
  ```bash
  # Ubuntu/Debian
  sudo apt install xclip

  # Fedora
  sudo dnf install xclip

  # Arch
  sudo pacman -S xclip
  ```

## Installation

### macOS / Linux

1. Open Terminal
2. Navigate to this directory:
   ```bash
   cd /path/to/copy-gif/native-host
   ```

3. Run the installation script:
   ```bash
   ./install-native-host.sh
   ```

4. Follow the prompts to select which browsers to install for

### Windows

1. Open Command Prompt or PowerShell **as Administrator**
2. Navigate to this directory:
   ```cmd
   cd C:\path\to\copy-gif\native-host
   ```

3. Run the installation script:
   ```cmd
   install-native-host.bat
   ```

4. Follow the prompts to select which browsers to install for

## Post-Installation Steps

After running the installation script, you need to configure the extension ID:

1. Open your browser and go to `chrome://extensions/` (or `brave://extensions/`, `edge://extensions/`, etc.)

2. Enable **Developer mode** (toggle in top right corner)

3. Click **"Load unpacked"** and select the `copy-gif` extension folder

4. Copy the **Extension ID** (it looks like: `abcdefghijklmnopqrstuvwxyz123456`)

5. Edit the native host manifest file for your browser:

   **macOS:**
   - Chrome: `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.copygif.host.json`
   - Brave: `~/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.copygif.host.json`
   - Edge: `~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/com.copygif.host.json`

   **Linux:**
   - Chrome: `~/.config/google-chrome/NativeMessagingHosts/com.copygif.host.json`
   - Brave: `~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.copygif.host.json`

   **Windows:**
   - The manifest is in this directory: `com.copygif.host.json`

6. Open the file and replace `PLACEHOLDER_EXTENSION_ID` with your actual Extension ID

7. **Restart your browser**

## Testing

1. Go to a website with animated GIFs (e.g., https://giphy.com)
2. Right-click on a GIF
3. Select **"Copy GIF"** from the context menu
4. You should see a success notification
5. Try pasting in:
   - Messages / iMessage (macOS)
   - Slack
   - Discord
   - Gmail
   - Any app that supports animated GIFs

## Troubleshooting

### "Native host not available" error

- Make sure you ran the installation script
- Check that Python 3 is installed: `python3 --version`
- Verify the extension ID is correct in the manifest file
- Restart your browser after making changes

### Extension works but copies only first frame

- The native host is not installed or not configured correctly
- Check the browser console (F12) for error messages
- Check the native host logs: `~/.copy-gif-extension/copy-gif-host.log`

### Permission denied errors (macOS/Linux)

- Make sure the scripts are executable:
  ```bash
  chmod +x copy-gif-host.py
  chmod +x install-native-host.sh
  ```

### Python not found (Windows)

- Install Python 3 from https://www.python.org/downloads/
- Make sure "Add Python to PATH" is checked during installation
- Restart Command Prompt after installation

## Uninstallation

### macOS / Linux

Remove the native host manifest files:

```bash
# Chrome
rm ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.copygif.host.json

# Brave
rm ~/Library/Application\ Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.copygif.host.json

# Linux Chrome
rm ~/.config/google-chrome/NativeMessagingHosts/com.copygif.host.json
```

### Windows

Remove the registry entries:

```cmd
reg delete "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.copygif.host" /f
reg delete "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.copygif.host" /f
```

## How it works

1. Extension detects a GIF and sends the URL to the native host
2. Native host downloads the GIF to a temporary file
3. Native host uses OS-specific clipboard commands:
   - **macOS**: AppleScript with GIF format support
   - **Windows**: PowerShell with file clipboard support
   - **Linux**: xclip or wl-copy with image/gif MIME type
4. Temporary file is cleaned up automatically

## Security

- The native host only accepts connections from your Copy GIF extension (verified by extension ID)
- All GIF downloads are temporary and deleted immediately after copying
- The host runs with your user permissions (no elevated privileges needed)
- All operations are logged to `~/.copy-gif-extension/copy-gif-host.log` for transparency
