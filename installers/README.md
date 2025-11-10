# Copy GIF - Installer Building

This directory contains scripts to build native installers for macOS, Windows, and Linux.

## Prerequisites

### All Platforms
- Rust toolchain installed (for building the binary)
- Run `cargo build --release` in `native-host/` before building installers

### macOS
- macOS 10.13 or later
- Xcode Command Line Tools
- No additional dependencies (uses built-in `pkgbuild` and `productbuild`)

### Windows
- Windows 10 or later
- Inno Setup or WiX Toolset (coming soon)

### Linux
- `dpkg` for Debian/Ubuntu packages
- `rpmbuild` for Fedora/RHEL packages (coming soon)

## Building Installers

### macOS (.pkg)

```bash
cd installers/macos
./build-pkg.sh
```

Output: `installers/macos/dist/CopyGIF-NativeHost-1.0.0.pkg` (~700KB)

**Features:**
- Professional installer with welcome and conclusion screens
- Automatically installs for Chrome, Brave, Edge, and Chromium
- Installs binary to `/usr/local/bin/copy-gif-host`
- Creates native messaging manifests
- Shows post-install instructions for Extension ID configuration

### Windows (.exe)

Coming soon!

### Linux (.deb / .rpm)

Coming soon!

## Testing the Installer

### macOS

1. **Build the installer** (see above)
2. **Test installation:**
   ```bash
   # Install the package
   sudo installer -pkg dist/CopyGIF-NativeHost-1.0.0.pkg -target /

   # Verify binary is installed
   which copy-gif-host
   # Should output: /usr/local/bin/copy-gif-host

   # Check manifest was created
   ls -la ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.copygif.host.json
   ```

3. **Configure Extension ID:**
   ```bash
   # Replace YOUR_EXTENSION_ID with your actual ID
   sed -i '' 's/PLACEHOLDER_EXTENSION_ID/YOUR_EXTENSION_ID/g' \
     ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.copygif.host.json
   ```

4. **Test the extension**
   - Restart Chrome
   - Go to giphy.com
   - Right-click on a GIF → "Copy GIF"
   - Should see: "Animated GIF copied to clipboard!"

## Distribution

### macOS

**Option 1: Direct Download**
- Host the `.pkg` file on your website or GitHub Releases
- Users download and double-click to install

**Option 2: Code Signing (Recommended for public distribution)**
```bash
# Sign the package with your Developer ID
productsign --sign "Developer ID Installer: Your Name (TEAM_ID)" \
  CopyGIF-NativeHost-1.0.0.pkg \
  CopyGIF-NativeHost-1.0.0-signed.pkg

# Notarize with Apple (required for macOS 10.15+)
xcrun notarytool submit CopyGIF-NativeHost-1.0.0-signed.pkg \
  --keychain-profile "AC_PASSWORD" \
  --wait

# Staple the notarization ticket
xcrun stapler staple CopyGIF-NativeHost-1.0.0-signed.pkg
```

### Future: Auto-updater

Consider implementing an auto-updater using:
- Sparkle framework (macOS)
- Squirrel (Windows)
- Built-in package managers (Linux)

## File Structure

```
installers/
├── README.md                   # This file
├── macos/
│   ├── build-pkg.sh           # Build script
│   ├── scripts/
│   │   └── postinstall        # Post-installation script
│   ├── payload/               # Generated (gitignored)
│   └── dist/                  # Generated (gitignored)
│       └── CopyGIF-NativeHost-1.0.0.pkg
├── windows/                   # Coming soon
└── linux/                     # Coming soon
```

## Troubleshooting

### macOS: "Package is damaged" error
- Package is not signed
- Sign with Developer ID or disable Gatekeeper for testing:
  ```bash
  sudo spctl --master-disable  # Disable (test only!)
  sudo spctl --master-enable   # Re-enable after testing
  ```

### macOS: Binary not found after installation
- Check if installed: `ls -l /usr/local/bin/copy-gif-host`
- Check permissions: `chmod +x /usr/local/bin/copy-gif-host`

### Extension still shows "first frame only"
- Extension ID not configured in manifest
- Run the sed command from the installer conclusion
- Restart browser completely (quit and reopen)
