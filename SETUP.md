# Quick Setup Guide

## Step 1: Load Extension in Browser

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable **"Developer mode"** (toggle in top right corner)
3. Click **"Load unpacked"**
4. Select the `copy-gif` folder
5. **Copy the Extension ID** displayed under the extension name (looks like: `abcdefghijklmnopqrstuvwxyz123456`)

## Step 2: Install Native Host (for Animated GIFs)

### macOS

Open Terminal and run:

```bash
cd native-host
./install-native-host.sh
```

When prompted:
- Select **y** for Chrome (or whichever browser you're using)
- The script will install the native host

### After Installation

1. The installer will tell you where the manifest file is located
2. Open that file (for Chrome on macOS it's at):
   ```
   ~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.copygif.host.json
   ```

3. **Replace `PLACEHOLDER_EXTENSION_ID`** with your actual Extension ID from Step 1

4. **Completely quit and restart Chrome** (Cmd+Q, not just close windows)

## Step 3: Test It!

1. Go to https://giphy.com
2. Right-click on any GIF
3. Select **"Copy GIF"**
4. You should see: "Animated GIF copied to clipboard!"
5. Try pasting in Messages, Slack, or any other app

## Troubleshooting

### If you see "first frame only" message:
- **Native host not connecting** - check the following:
  - Verify the binary exists at `native-host/target/release/copy-gif-host`
  - If not, run `cargo build --release` in the native-host directory
  - Check the manifest file path points to the correct binary location
- Check the extension ID in the manifest file matches your extension ID
- **Completely quit and restart Chrome** (Cmd+Q) after making changes
- Check logs: `~/.copy-gif-extension/copy-gif-host.log`

### If you see "No GIF found" or "Not a GIF file":
- Make sure you're right-clicking directly on the image/GIF
- Try refreshing the page (F5) to reload the content script
- The extension works best on sites like Giphy, Tenor, Twitter, etc.

### If the context menu doesn't appear:
- Refresh the page after installing/reloading the extension
- Check that the extension is enabled in `chrome://extensions/`
- The context menu appears when right-clicking on images and links

### Check the logs:
- Native host logs: `~/.copy-gif-extension/copy-gif-host.log`
- Chrome extension console: `chrome://extensions/` → Click "Inspect views: service worker"
- Page console: Right-click page → Inspect → Console tab

## Success Indicators

✅ **Native host working:** Notification says "Animated GIF copied to clipboard!"
❌ **Fallback mode:** Notification says "Image copied to clipboard (as PNG - first frame only)"

When native host is working, you can paste animated GIFs into:
- Messages / iMessage
- Slack
- Discord
- Telegram
- Gmail
- WhatsApp Web
- And more!
