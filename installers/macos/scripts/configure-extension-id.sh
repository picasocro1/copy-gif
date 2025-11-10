#!/bin/bash

# Helper script to configure Extension ID after installation

set -e

MANIFEST_NAME="com.copygif.host.json"

echo "========================================"
echo "Copy GIF - Extension ID Configuration"
echo "========================================"
echo ""

# Function to update manifest file
update_manifest() {
    local manifest_path="$1"
    local extension_id="$2"

    if [ ! -f "$manifest_path" ]; then
        echo "  ✗ Manifest not found: $manifest_path"
        return 1
    fi

    # Update the manifest
    sed -i '' "s/PLACEHOLDER_EXTENSION_ID/$extension_id/g" "$manifest_path"
    echo "  ✓ Updated: $manifest_path"
}

# Prompt for Extension ID using AppleScript (GUI dialog)
EXTENSION_ID=$(osascript <<'EOF'
set dialogText to "Please enter your Copy GIF Extension ID:" & return & return & "You can find it at chrome://extensions/"
set defaultAnswer to ""

display dialog dialogText default answer defaultAnswer buttons {"Cancel", "OK"} default button "OK" with title "Copy GIF Configuration" with icon note

text returned of result
EOF
)

# Check if user cancelled
if [ $? -ne 0 ] || [ -z "$EXTENSION_ID" ]; then
    echo "Configuration cancelled."
    exit 1
fi

# Trim whitespace
EXTENSION_ID=$(echo "$EXTENSION_ID" | xargs)

# Validate Extension ID format (should be 32 lowercase letters)
if ! [[ "$EXTENSION_ID" =~ ^[a-z]{32}$ ]]; then
    osascript -e "display alert \"Invalid Extension ID\" message \"Extension ID should be 32 lowercase letters (a-z).\" as critical"
    exit 1
fi

echo "Configuring Extension ID: $EXTENSION_ID"
echo ""

# Update manifests for all browsers
UPDATED_COUNT=0

# Chrome
CHROME_MANIFEST="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/$MANIFEST_NAME"
if [ -f "$CHROME_MANIFEST" ]; then
    if grep -q "PLACEHOLDER_EXTENSION_ID" "$CHROME_MANIFEST"; then
        update_manifest "$CHROME_MANIFEST" "$EXTENSION_ID"
        ((UPDATED_COUNT++))
    else
        echo "  ↻ Chrome manifest already configured"
    fi
fi

# Chromium
CHROMIUM_MANIFEST="$HOME/Library/Application Support/Chromium/NativeMessagingHosts/$MANIFEST_NAME"
if [ -f "$CHROMIUM_MANIFEST" ]; then
    if grep -q "PLACEHOLDER_EXTENSION_ID" "$CHROMIUM_MANIFEST"; then
        update_manifest "$CHROMIUM_MANIFEST" "$EXTENSION_ID"
        ((UPDATED_COUNT++))
    else
        echo "  ↻ Chromium manifest already configured"
    fi
fi

# Brave
BRAVE_MANIFEST="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/$MANIFEST_NAME"
if [ -f "$BRAVE_MANIFEST" ]; then
    if grep -q "PLACEHOLDER_EXTENSION_ID" "$BRAVE_MANIFEST"; then
        update_manifest "$BRAVE_MANIFEST" "$EXTENSION_ID"
        ((UPDATED_COUNT++))
    else
        echo "  ↻ Brave manifest already configured"
    fi
fi

# Edge
EDGE_MANIFEST="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts/$MANIFEST_NAME"
if [ -f "$EDGE_MANIFEST" ]; then
    if grep -q "PLACEHOLDER_EXTENSION_ID" "$EDGE_MANIFEST"; then
        update_manifest "$EDGE_MANIFEST" "$EXTENSION_ID"
        ((UPDATED_COUNT++))
    else
        echo "  ↻ Edge manifest already configured"
    fi
fi

echo ""
echo "========================================"
echo "✓ Configuration Complete!"
echo "========================================"
echo ""
echo "Updated $UPDATED_COUNT manifest(s)."
echo ""
echo "Next steps:"
echo "1. Restart your browser completely (quit and reopen)"
echo "2. Go to https://giphy.com"
echo "3. Right-click on a GIF → 'Copy GIF'"
echo "4. You should see: 'Animated GIF copied to clipboard!'"
echo ""

# Show success dialog
osascript -e "display notification \"Extension ID configured successfully! Restart your browser to use Copy GIF.\" with title \"Copy GIF\" sound name \"Glass\""

exit 0
