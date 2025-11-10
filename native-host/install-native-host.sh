#!/bin/bash

# Installation script for Copy GIF Native Messaging Host
# Supports macOS and Linux

set -e

echo "========================================"
echo "Copy GIF - Native Host Installer"
echo "========================================"
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    OS_TYPE="macOS";;
    Linux*)     OS_TYPE="Linux";;
    *)          echo "Unsupported OS: ${OS}"; exit 1;;
esac

echo "Detected OS: ${OS_TYPE}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST_BINARY="${SCRIPT_DIR}/target/release/copy-gif-host"
HOST_MANIFEST="${SCRIPT_DIR}/com.copygif.host.json"

# Check if manifest exists
if [ ! -f "${HOST_MANIFEST}" ]; then
    echo "Error: com.copygif.host.json not found!"
    exit 1
fi

# Check if binary exists, if not, build it
if [ ! -f "${HOST_BINARY}" ]; then
    echo "Binary not found. Building from source..."
    echo ""

    # Check if cargo is installed
    if ! command -v cargo &> /dev/null; then
        echo "Error: Rust/Cargo is not installed!"
        echo ""
        echo "Please install Rust from: https://rustup.rs/"
        echo "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi

    # Build the binary
    echo "Building native host binary..."
    cd "${SCRIPT_DIR}"
    cargo build --release

    if [ ! -f "${HOST_BINARY}" ]; then
        echo "Error: Build failed!"
        exit 1
    fi

    echo "✓ Build successful!"
    echo ""
fi

echo "Using binary: ${HOST_BINARY}"
echo ""

# Determine native messaging host directory based on OS and browser
if [ "${OS_TYPE}" = "macOS" ]; then
    CHROME_DIR="${HOME}/Library/Application Support/Google/Chrome/NativeMessagingHosts"
    CHROMIUM_DIR="${HOME}/Library/Application Support/Chromium/NativeMessagingHosts"
    BRAVE_DIR="${HOME}/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    EDGE_DIR="${HOME}/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
else
    CHROME_DIR="${HOME}/.config/google-chrome/NativeMessagingHosts"
    CHROMIUM_DIR="${HOME}/.config/chromium/NativeMessagingHosts"
    BRAVE_DIR="${HOME}/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    EDGE_DIR="${HOME}/.config/microsoft-edge/NativeMessagingHosts"
fi

# Function to install for a specific browser
install_for_browser() {
    local browser_name=$1
    local install_dir=$2

    echo "Installing for ${browser_name}..."

    # Create directory if it doesn't exist
    mkdir -p "${install_dir}"

    # Create a modified manifest with the correct path (pointing to the Rust binary)
    sed "s|PLACEHOLDER_PATH|${HOST_BINARY}|g" "${HOST_MANIFEST}" > "${install_dir}/com.copygif.host.json"

    echo "  ✓ Installed to: ${install_dir}"
}

# Ask user which browsers to install for
echo "Which browsers would you like to install the native host for?"
echo ""

read -p "Install for Chrome? (y/n) " -n 1 -r INSTALL_CHROME
echo ""
if [[ $INSTALL_CHROME =~ ^[Yy]$ ]]; then
    install_for_browser "Chrome" "${CHROME_DIR}"
fi

read -p "Install for Chromium? (y/n) " -n 1 -r INSTALL_CHROMIUM
echo ""
if [[ $INSTALL_CHROMIUM =~ ^[Yy]$ ]]; then
    install_for_browser "Chromium" "${CHROMIUM_DIR}"
fi

read -p "Install for Brave? (y/n) " -n 1 -r INSTALL_BRAVE
echo ""
if [[ $INSTALL_BRAVE =~ ^[Yy]$ ]]; then
    install_for_browser "Brave" "${BRAVE_DIR}"
fi

read -p "Install for Edge? (y/n) " -n 1 -r INSTALL_EDGE
echo ""
if [[ $INSTALL_EDGE =~ ^[Yy]$ ]]; then
    install_for_browser "Edge" "${EDGE_DIR}"
fi

echo ""
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo ""
echo "IMPORTANT: You need to update the manifest with your extension ID!"
echo ""
echo "Steps:"
echo "1. Load your extension in Chrome (chrome://extensions/)"
echo "2. Copy the Extension ID (it looks like: abcdefghijklmnopqrstuvwxyz123456)"
echo "3. Edit each installed manifest file and replace PLACEHOLDER_EXTENSION_ID"
echo ""
echo "Manifest locations:"
[[ $INSTALL_CHROME =~ ^[Yy]$ ]] && echo "  Chrome:   ${CHROME_DIR}/com.copygif.host.json"
[[ $INSTALL_CHROMIUM =~ ^[Yy]$ ]] && echo "  Chromium: ${CHROMIUM_DIR}/com.copygif.host.json"
[[ $INSTALL_BRAVE =~ ^[Yy]$ ]] && echo "  Brave:    ${BRAVE_DIR}/com.copygif.host.json"
[[ $INSTALL_EDGE =~ ^[Yy]$ ]] && echo "  Edge:     ${EDGE_DIR}/com.copygif.host.json"
echo ""

if [ "${OS_TYPE}" = "Linux" ]; then
    echo "Note: On Linux, make sure you have either 'xclip' or 'wl-copy' installed:"
    echo "  Ubuntu/Debian: sudo apt install xclip"
    echo "  Fedora: sudo dnf install xclip"
    echo "  Arch: sudo pacman -S xclip"
    echo ""
fi

echo "After updating the extension ID, restart your browser for changes to take effect."
echo ""
