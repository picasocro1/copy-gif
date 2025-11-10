#!/opt/homebrew/opt/python@3.12/libexec/bin/python3
"""
Native Messaging Host for Copy GIF Extension
Handles copying animated GIFs to clipboard using OS-specific methods
"""

import sys
import json
import struct
import os
import platform
import subprocess
import tempfile
import urllib.request
import logging
from pathlib import Path

# Setup logging
log_dir = Path.home() / '.copy-gif-extension'
log_dir.mkdir(exist_ok=True)
logging.basicConfig(
    filename=log_dir / 'copy-gif-host.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def send_message(message):
    """Send message to extension"""
    encoded_message = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('I', len(encoded_message)))
    sys.stdout.buffer.write(encoded_message)
    sys.stdout.buffer.flush()
    logging.debug(f"Sent message: {message}")

def read_message():
    """Read message from extension"""
    try:
        raw_length = sys.stdin.buffer.read(4)
        if not raw_length:
            logging.info("No message to read, exiting")
            sys.exit(0)

        message_length = struct.unpack('I', raw_length)[0]
        logging.debug(f"Message length: {message_length}")

        message = sys.stdin.buffer.read(message_length).decode('utf-8')
        logging.debug(f"Received message: {message}")
        return json.loads(message)
    except Exception as e:
        logging.error(f"Error reading message: {e}")
        raise

def download_gif(url):
    """Download GIF from URL to temporary file"""
    try:
        # Try to convert WebP URLs to GIF URLs (common on Giphy, Tenor, etc.)
        original_url = url
        if url.endswith('.webp'):
            url = url[:-5] + '.gif'
            logging.info(f"Converted WebP URL to GIF: {url}")

        # Create temp file with .gif extension
        temp_fd, temp_path = tempfile.mkstemp(suffix='.gif', prefix='copygif_')
        os.close(temp_fd)

        logging.info(f"Downloading GIF from: {url}")

        # Try to download the GIF version
        try:
            urllib.request.urlretrieve(url, temp_path)
        except Exception as e:
            # If GIF version fails and we converted from WebP, try original URL
            if url != original_url:
                logging.warning(f"GIF URL failed, trying original WebP URL: {original_url}")
                urllib.request.urlretrieve(original_url, temp_path)
            else:
                raise

        logging.info(f"Downloaded to: {temp_path}")

        # Verify the file is actually a GIF
        with open(temp_path, 'rb') as f:
            header = f.read(6)
            if not (header.startswith(b'GIF87a') or header.startswith(b'GIF89a')):
                logging.warning(f"Downloaded file is not a GIF (header: {header[:6]})")
                raise Exception("Downloaded file is not a valid GIF format")

        return temp_path

    except Exception as e:
        logging.error(f"Error downloading GIF: {e}")
        raise

def copy_to_clipboard_macos(file_path):
    """Copy GIF to clipboard on macOS using osascript"""
    try:
        # Use AppleScript to copy the GIF file to clipboard
        # This preserves the animation
        applescript = f'''
        set the clipboard to (read (POSIX file "{file_path}") as «class GIFf»)
        '''

        result = subprocess.run(
            ['osascript', '-e', applescript],
            capture_output=True,
            text=True,
            check=True
        )

        logging.info("Successfully copied GIF to clipboard (macOS)")
        return True

    except subprocess.CalledProcessError as e:
        logging.error(f"osascript error: {e.stderr}")
        raise Exception(f"Failed to copy to clipboard: {e.stderr}")

    except Exception as e:
        logging.error(f"Error copying to clipboard (macOS): {e}")
        raise

def copy_to_clipboard_windows(file_path):
    """Copy GIF to clipboard on Windows using PowerShell"""
    try:
        # PowerShell script to copy file to clipboard
        powershell_script = f'''
        Add-Type -AssemblyName System.Windows.Forms
        $file = Get-Item -LiteralPath "{file_path}"
        $dataObject = New-Object System.Windows.Forms.DataObject
        $dataObject.SetFileDropList([System.Collections.Specialized.StringCollection]::new())
        $dataObject.GetFileDropList().Add($file.FullName)
        [System.Windows.Forms.Clipboard]::SetDataObject($dataObject, $true)
        '''

        result = subprocess.run(
            ['powershell', '-Command', powershell_script],
            capture_output=True,
            text=True,
            check=True
        )

        logging.info("Successfully copied GIF to clipboard (Windows)")
        return True

    except subprocess.CalledProcessError as e:
        logging.error(f"PowerShell error: {e.stderr}")
        raise Exception(f"Failed to copy to clipboard: {e.stderr}")

    except Exception as e:
        logging.error(f"Error copying to clipboard (Windows): {e}")
        raise

def copy_to_clipboard_linux(file_path):
    """Copy GIF to clipboard on Linux using xclip"""
    try:
        # First, try with xclip
        result = subprocess.run(
            ['xclip', '-selection', 'clipboard', '-t', 'image/gif', '-i', file_path],
            capture_output=True,
            text=True,
            check=True
        )

        logging.info("Successfully copied GIF to clipboard (Linux/xclip)")
        return True

    except FileNotFoundError:
        # xclip not installed, try wl-copy (Wayland)
        try:
            result = subprocess.run(
                ['wl-copy', '--type', 'image/gif', '<', file_path],
                capture_output=True,
                text=True,
                check=True,
                shell=True
            )

            logging.info("Successfully copied GIF to clipboard (Linux/wl-copy)")
            return True

        except Exception as e:
            logging.error(f"wl-copy error: {e}")
            raise Exception("Neither xclip nor wl-copy is installed. Please install one of them.")

    except subprocess.CalledProcessError as e:
        logging.error(f"xclip error: {e.stderr}")
        raise Exception(f"Failed to copy to clipboard: {e.stderr}")

    except Exception as e:
        logging.error(f"Error copying to clipboard (Linux): {e}")
        raise

def copy_gif_to_clipboard(file_path):
    """Copy GIF to clipboard using appropriate method for current OS"""
    system = platform.system()

    logging.info(f"Copying to clipboard on {system}")

    if system == 'Darwin':  # macOS
        return copy_to_clipboard_macos(file_path)
    elif system == 'Windows':
        return copy_to_clipboard_windows(file_path)
    elif system == 'Linux':
        return copy_to_clipboard_linux(file_path)
    else:
        raise Exception(f"Unsupported operating system: {system}")

def cleanup_temp_file(file_path):
    """Remove temporary file"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            logging.info(f"Cleaned up temp file: {file_path}")
    except Exception as e:
        logging.warning(f"Failed to cleanup temp file: {e}")

def handle_message(message):
    """Handle message from extension"""
    action = message.get('action')

    if action == 'copyGif':
        url = message.get('url')

        if not url:
            send_message({'success': False, 'error': 'No URL provided'})
            return

        temp_file = None

        try:
            # Download GIF
            temp_file = download_gif(url)

            # Copy to clipboard
            copy_gif_to_clipboard(temp_file)

            # Send success response
            send_message({'success': True, 'method': 'native'})

        except Exception as e:
            logging.error(f"Error handling message: {e}")
            send_message({'success': False, 'error': str(e)})

        finally:
            # Cleanup temp file
            if temp_file:
                cleanup_temp_file(temp_file)

    else:
        send_message({'success': False, 'error': f'Unknown action: {action}'})

def main():
    """Main function"""
    try:
        logging.info("Native messaging host started")
        logging.info(f"Platform: {platform.system()}")
        logging.info(f"Python version: {sys.version}")

        # Read and handle message
        message = read_message()
        handle_message(message)

    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        try:
            send_message({'success': False, 'error': str(e)})
        except:
            pass

    finally:
        logging.info("Native messaging host exiting")

if __name__ == '__main__':
    main()
