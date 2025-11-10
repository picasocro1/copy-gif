#!/bin/bash

# Build script for Copy GIF macOS installer package

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
VERSION="1.0.0"
IDENTIFIER="com.copygif.nativehost"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "========================================"
echo "Copy GIF - macOS Installer Builder"
echo "========================================"
echo ""

# Check if binary exists
BINARY_SOURCE="$PROJECT_ROOT/native-host/target/release/copy-gif-host"
if [ ! -f "$BINARY_SOURCE" ]; then
    echo "Error: Binary not found at $BINARY_SOURCE"
    echo "Please build the binary first:"
    echo "  cd native-host && cargo build --release"
    exit 1
fi

# Copy binary and helper script to payload
echo "Copying files to payload..."
mkdir -p "$SCRIPT_DIR/payload/usr/local/bin"
cp "$BINARY_SOURCE" "$SCRIPT_DIR/payload/usr/local/bin/"
chmod +x "$SCRIPT_DIR/payload/usr/local/bin/copy-gif-host"

# Copy configuration helper
cp "$SCRIPT_DIR/scripts/configure-extension-id.sh" "$SCRIPT_DIR/payload/usr/local/bin/copy-gif-configure"
chmod +x "$SCRIPT_DIR/payload/usr/local/bin/copy-gif-configure"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build component package
echo "Building component package..."
pkgbuild \
    --root "$SCRIPT_DIR/payload" \
    --scripts "$SCRIPT_DIR/scripts" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    "$OUTPUT_DIR/copy-gif-component.pkg"

# Create distribution XML
echo "Creating distribution definition..."
cat > "$OUTPUT_DIR/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Copy GIF Native Host</title>
    <organization>com.copygif</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="true" hostArchitectures="arm64,x86_64"/>

    <welcome file="welcome.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>

    <pkg-ref id="$IDENTIFIER" version="$VERSION">copy-gif-component.pkg</pkg-ref>

    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>

    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
</installer-gui-script>
EOF

# Create welcome message
echo "Creating welcome message..."
cat > "$OUTPUT_DIR/welcome.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { font-size: 24px; font-weight: 600; }
        p { font-size: 14px; line-height: 1.5; }
        .important { background-color: #fff3cd; padding: 10px; border-radius: 4px; margin: 15px 0; }
    </style>
</head>
<body>
    <h1>Welcome to Copy GIF Native Host Installer</h1>
    <p>This installer will install the Copy GIF native messaging host, which enables the Chrome extension to copy animated GIFs to your clipboard.</p>

    <div class="important">
        <p><strong>Important:</strong> After installation, a configuration helper will launch to set up your Extension ID. If it doesn't launch automatically, you can run:</p>
        <p><code>/usr/local/bin/copy-gif-configure</code></p>
    </div>

    <p><strong>What will be installed:</strong></p>
    <ul>
        <li>Native host binary: <code>/usr/local/bin/copy-gif-host</code></li>
        <li>Configuration helper: <code>/usr/local/bin/copy-gif-configure</code></li>
        <li>Native messaging manifests for Chrome, Brave, Edge, and Chromium</li>
    </ul>
</body>
</html>
EOF

# Create conclusion message
echo "Creating conclusion message..."
cat > "$OUTPUT_DIR/conclusion.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { font-size: 24px; font-weight: 600; color: #28a745; }
        h2 { font-size: 18px; font-weight: 600; margin-top: 20px; }
        p { font-size: 14px; line-height: 1.5; }
        code { background-color: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: Monaco, monospace; font-size: 12px; }
        ol { line-height: 1.8; }
        .warning { background-color: #fff3cd; padding: 15px; border-radius: 4px; margin: 15px 0; }
    </style>
</head>
<body>
    <h1>✓ Installation Complete!</h1>

    <div class="warning">
        <h2>⚠️ One More Step: Configure Extension ID</h2>
        <p>A configuration helper should have launched automatically. If not:</p>
        <ol>
            <li>Open Terminal</li>
            <li>Run: <code>/usr/local/bin/copy-gif-configure</code></li>
            <li>Enter your Extension ID when prompted (find it at <code>chrome://extensions/</code>)</li>
            <li>Restart Chrome</li>
        </ol>
        <p><strong>Alternative (Manual):</strong> If you prefer, you can manually edit the manifest file and replace <code>PLACEHOLDER_EXTENSION_ID</code> with your Extension ID.</p>
    </div>

    <h2>Testing</h2>
    <p>After configuration:</p>
    <ol>
        <li>Go to <a href="https://giphy.com">giphy.com</a></li>
        <li>Right-click on any GIF</li>
        <li>Select "Copy GIF"</li>
        <li>You should see: "Animated GIF copied to clipboard!"</li>
    </ol>

    <p><strong>For other browsers:</strong> Update the manifest in their respective directories using the same command pattern.</p>
</body>
</html>
EOF

# Build final distribution package
echo "Building distribution package..."
productbuild \
    --distribution "$OUTPUT_DIR/distribution.xml" \
    --package-path "$OUTPUT_DIR" \
    --resources "$OUTPUT_DIR" \
    "$OUTPUT_DIR/CopyGIF-NativeHost-${VERSION}.pkg"

# Clean up intermediate files
rm -f "$OUTPUT_DIR/copy-gif-component.pkg"
rm -f "$OUTPUT_DIR/distribution.xml"
rm -f "$OUTPUT_DIR/welcome.html"
rm -f "$OUTPUT_DIR/conclusion.html"

echo ""
echo "========================================"
echo "✓ Package Built Successfully!"
echo "========================================"
echo ""
echo "Installer location:"
echo "  $OUTPUT_DIR/CopyGIF-NativeHost-${VERSION}.pkg"
echo ""
echo "You can now distribute this .pkg file to users!"
echo ""

# Get file size
SIZE=$(du -h "$OUTPUT_DIR/CopyGIF-NativeHost-${VERSION}.pkg" | cut -f1)
echo "Package size: $SIZE"
echo ""
