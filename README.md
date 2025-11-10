# Copy GIF - Chrome Extension

A Chrome extension that allows you to copy animated GIFs to your clipboard, preserving the animation.

## The Problem

When you right-click and select "Copy Image" on an animated GIF in your browser, only the first frame is copied. This is because the browser's native Clipboard API doesn't support animated GIFs.

## The Solution

This extension provides two ways to copy GIFs:

1. **Native Host (Recommended)** - Copies the full animated GIF using OS-level clipboard commands
2. **Fallback Mode** - Copies the first frame as PNG if native host isn't installed

## Features

- Right-click context menu option "Copy GIF"
- **Preserves GIF animation** when native host is installed
- Works on any website with GIF images (Giphy, Tenor, Twitter, etc.)
- **Automatically converts WebP to GIF** when available
- Finds GIFs in:
  - `<img>` tags
  - `<picture>` elements
  - CSS background images
  - Direct image URLs from context menu
- Cross-platform support (macOS, Windows, Linux)
- Graceful fallback if native host not available

## Installation

### 1. Install the Extension

1. Clone or download this repository
2. Open Chrome and go to `chrome://extensions/`
3. Enable **Developer mode** (toggle in top right)
4. Click **"Load unpacked"**
5. Select the `copy-gif` folder

### 2. Install Native Host (For Animated GIFs)

**Important:** Without the native host, the extension will only copy the first frame as PNG.

See detailed instructions in [`native-host/README.md`](native-host/README.md)

**Quick install:**

**macOS/Linux:**
```bash
cd native-host
./install-native-host.sh
```

**Windows:**
```cmd
cd native-host
install-native-host.bat
```

Then follow the prompts and configure your extension ID as described in the native host README.

## Usage

1. Navigate to any webpage with animated GIFs (e.g., giphy.com, tenor.com)
2. Right-click on a GIF (or near it)
3. Select **"Copy GIF"** from the context menu
4. Paste into any application that supports images:
   - Slack, Discord, Messages
   - Gmail, Outlook
   - Any image editor
   - And more!

## How It Works

### With Native Host (Animated GIFs)

1. Extension finds the GIF URL in the page
2. Sends URL to native messaging host
3. Native host downloads GIF to temp file
4. Native host uses OS-specific clipboard commands:
   - **macOS**: AppleScript with GIF format
   - **Windows**: PowerShell file clipboard
   - **Linux**: xclip/wl-copy with image/gif MIME type
5. Temp file is deleted automatically

### Without Native Host (First Frame Only)

1. Extension finds and downloads the GIF
2. Converts first frame to PNG using Canvas
3. Copies PNG to clipboard using browser Clipboard API

## Browser Support

- Chrome (recommended)
- Chromium
- Brave
- Microsoft Edge
- Any Chromium-based browser

## Requirements

### Extension Only
- No special requirements

### Native Host (for animated GIFs)
- Python 3 (usually pre-installed)
- **Linux only**: `xclip` or `wl-copy`

## Troubleshooting

### "No GIF found" error
- Make sure you're clicking on or near an image element
- The extension searches the clicked element and its descendants
- Check browser console (F12) for more details

### Only first frame is copied (PNG fallback mode)
- Native host is not installed or not connecting
- **Most common issue**: Python path in shebang line
  - Run `which python3` to find your Python path
  - Edit first line of `native-host/copy-gif-host.py` with absolute path
  - Example: `#!/opt/homebrew/opt/python@3.12/libexec/bin/python3`
- Check extension ID matches in manifest file
- **Completely quit and restart Chrome** (Cmd+Q on macOS)
- Check native host logs: `~/.copy-gif-extension/copy-gif-host.log`

### "Native host not available" or "Native host has exited"
- Native host can't find Python interpreter
- Update the shebang line in `copy-gif-host.py` with absolute Python path
- Verify Python 3 is installed: `python3 --version`
- Check manifest file has correct extension ID
- See [SETUP.md](SETUP.md) for detailed troubleshooting

## Development

See [`ROADMAP.md`](ROADMAP.md) for development progress and planned features.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
