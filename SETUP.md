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
cd /Users/maciejkubiak/Documents/Projects/copy-gif/native-host
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

3. Replace `PLACEHOLDER_EXTENSION_ID` with your actual Extension ID from Step 1

4. **Restart Chrome**

## Step 3: Test It!

1. Go to https://giphy.com
2. Right-click on any GIF
3. Select **"Copy GIF"**
4. You should see: "Animated GIF copied to clipboard!"
5. Try pasting in Messages, Slack, or any other app

## Troubleshooting

### If you see "first frame only" message:
- Native host not installed correctly
- Check that Python 3 is available: `python3 --version`
- Check the extension ID in the manifest file matches your extension ID
- Restart Chrome after making changes

### If nothing happens:
- Check Chrome console (F12) for errors
- Check native host logs: `~/.copy-gif-extension/copy-gif-host.log`
- Make sure the Python script is executable: `chmod +x native-host/copy-gif-host.py`

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
