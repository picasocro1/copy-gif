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

**Recommended: Use the installer (macOS)**

Download the latest `.pkg` installer from [Releases](https://github.com/YOUR_USERNAME/copy-gif/releases):
- Double-click to install
- Follow post-install instructions to configure your Extension ID
- Restart Chrome

**Alternative: Manual installation (All platforms)**

```bash
cd native-host
./install-native-host.sh
```

Then follow the prompts and configure your extension ID as described in [SETUP.md](SETUP.md).

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
2. Sends URL to native messaging host (written in Rust)
3. Native host downloads GIF to temp file
4. Native host uses OS-specific clipboard commands:
   - **macOS**: Native Cocoa APIs with GIF format support
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
- No dependencies! (Rust binary is self-contained)
- **Linux only**: `xclip` or `wl-copy` (for clipboard access)

## Troubleshooting

### "No GIF found" error
- Make sure you're clicking on or near an image element
- The extension searches the clicked element and its descendants
- Check browser console (F12) for more details

### Only first frame is copied (PNG fallback mode)
- Native host is not installed or not connecting
- **Most common issue**: Binary not built or wrong path in manifest
  - Check if binary exists: `native-host/target/release/copy-gif-host`
  - If not, build it: `cd native-host && cargo build --release`
  - Verify manifest path points to the binary
- Check extension ID matches in manifest file
- **Completely quit and restart Chrome** (Cmd+Q on macOS)
- Check native host logs: `~/.copy-gif-extension/copy-gif-host.log`

### "Native host not available" or "Native host has exited"
- Native host binary not found or not executable
- Build the binary: `cd native-host && cargo build --release`
- Check manifest file has correct path and extension ID
- See [SETUP.md](SETUP.md) for detailed troubleshooting

## Development

See [`ROADMAP.md`](ROADMAP.md) for development progress and planned features.

### Building the Native Host from Source

The native host is written in **Rust** for maximum performance and minimal dependencies.

**Prerequisites:**
- Install Rust: https://rustup.rs/
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

**Build:**
```bash
cd native-host
cargo build --release
```

The compiled binary will be in `native-host/target/release/copy-gif-host`

**Binary sizes (optimized):**
- macOS (ARM64): ~1.4MB
- macOS (x86_64): ~1.5MB
- Windows: ~1.6MB
- Linux: ~1.8MB

**Note:** The native host is built automatically by the installer. The Rust source code is in `native-host/src/` for those interested in building from source.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
