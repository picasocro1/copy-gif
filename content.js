// Content script for Copy GIF extension

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'copyGif') {
    // Check if we have a direct URL or need to find it via coordinates
    if (message.directUrl) {
      handleCopyGifWithUrl(message.directUrl);
    } else {
      handleCopyGif(message.x, message.y);
    }
  }
  return true; // Keep message channel open for async response
});

/**
 * Handle copying GIF when we have a direct URL
 */
async function handleCopyGifWithUrl(url) {
  try {
    console.log('Attempting to copy from URL:', url);

    // Quick check if URL looks like a GIF
    if (!isGifUrl(url)) {
      // URL doesn't look like a GIF, but it might still be one (e.g., served with unusual URL)
      // Let's check the actual content type
      console.warn('URL doesn\'t look like a GIF, will verify content type:', url);
    }

    // For images from context menu, try to copy directly
    // We'll determine if it's actually a GIF during the fetch
    await copyGifToClipboard(url);

  } catch (error) {
    console.error('Error copying GIF:', error);
    showNotification('Failed to copy GIF: ' + error.message, 'error');
  }
}

/**
 * Main function to handle copying GIF (coordinate-based)
 */
async function handleCopyGif(x, y) {
  try {
    // Find the element at the clicked position
    const element = document.elementFromPoint(x, y);

    if (!element) {
      showNotification('No element found at clicked position', 'error');
      return;
    }

    // Search for GIF in the clicked element and its descendants
    const gifUrl = findGifInElement(element);

    if (!gifUrl) {
      showNotification('No GIF found in the clicked element', 'error');
      return;
    }

    console.log('Found GIF:', gifUrl);

    // Fetch and copy the GIF
    await copyGifToClipboard(gifUrl);

  } catch (error) {
    console.error('Error copying GIF:', error);
    showNotification('Failed to copy GIF: ' + error.message, 'error');
  }
}

/**
 * Recursively search for GIF in element and its descendants
 * Returns the URL of the first GIF found, or null
 */
function findGifInElement(element) {
  if (!element) return null;

  // Check if element itself is an img tag with GIF
  if (element.tagName === 'IMG') {
    const src = element.src || element.currentSrc;
    if (src && isGifUrl(src)) {
      return src;
    }
  }

  // Check for picture element with GIF source
  if (element.tagName === 'PICTURE') {
    const sources = element.querySelectorAll('source');
    for (const source of sources) {
      const srcset = source.srcset;
      if (srcset && isGifUrl(srcset)) {
        return srcset.split(' ')[0]; // Get first URL from srcset
      }
    }
    // Also check img inside picture
    const img = element.querySelector('img');
    if (img) {
      const src = img.src || img.currentSrc;
      if (src && isGifUrl(src)) {
        return src;
      }
    }
  }

  // Check for background-image in CSS
  const bgImage = window.getComputedStyle(element).backgroundImage;
  if (bgImage && bgImage !== 'none') {
    const urlMatch = bgImage.match(/url\(['"]?(.+?)['"]?\)/);
    if (urlMatch && urlMatch[1] && isGifUrl(urlMatch[1])) {
      return urlMatch[1];
    }
  }

  // Search in child elements (recursive search)
  const images = element.querySelectorAll('img');
  for (const img of images) {
    const src = img.src || img.currentSrc;
    if (src && isGifUrl(src)) {
      return src;
    }
  }

  // Search for background images in descendants
  const allElements = element.querySelectorAll('*');
  for (const el of allElements) {
    const bg = window.getComputedStyle(el).backgroundImage;
    if (bg && bg !== 'none') {
      const urlMatch = bg.match(/url\(['"]?(.+?)['"]?\)/);
      if (urlMatch && urlMatch[1] && isGifUrl(urlMatch[1])) {
        return urlMatch[1];
      }
    }
  }

  return null;
}

/**
 * Check if URL points to a GIF file
 */
function isGifUrl(url) {
  if (!url) return false;

  // Remove query parameters and fragments for checking
  const urlWithoutParams = url.split('?')[0].split('#')[0];

  // Check if URL ends with .gif (case insensitive)
  return /\.gif$/i.test(urlWithoutParams);
}

/**
 * Fetch image from URL and copy to clipboard
 */
async function copyGifToClipboard(url) {
  try {
    console.log('Fetching image from URL:', url);

    // First, fetch to check the actual content type
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const blob = await response.blob();
    const contentType = blob.type;

    console.log('Image content type:', contentType, 'Size:', blob.size);

    // Check if it's actually a GIF (be lenient - accept if URL suggests it's a GIF or if content type is GIF)
    const urlLooksLikeGif = url.toLowerCase().includes('gif') || url.toLowerCase().includes('giphy');
    const isActuallyGif = contentType.includes('gif');

    console.log('URL looks like GIF:', urlLooksLikeGif, 'Content type is GIF:', isActuallyGif);

    if (!isActuallyGif && !urlLooksLikeGif) {
      // Not a GIF at all
      const fileType = contentType.split('/')[1] || 'unknown';
      showNotification(`Not a GIF file - this is a ${fileType.toUpperCase()} image`, 'error');
      return;
    }

    // If content type isn't GIF but URL suggests it should be, warn but try anyway
    if (!isActuallyGif && urlLooksLikeGif) {
      console.warn('URL suggests GIF but content type is:', contentType, '- attempting anyway');
    }

    // Try native messaging host first (preserves animation)
    const nativeResult = await tryNativeMessaging(url);

    if (nativeResult.success) {
      showNotification('Animated GIF copied to clipboard!', 'success');
      return;
    }

    // Fallback to Clipboard API if native messaging failed
    console.warn('Native messaging failed, falling back to Clipboard API:', nativeResult.error);

    // Copy blob to clipboard (will auto-fallback to PNG if needed)
    const result = await copyBlobToClipboard(blob);

    // Show appropriate success message
    if (result && result.asPng) {
      showNotification('Image copied to clipboard (as PNG - first frame only)\n\nTip: Install native host for animated GIFs!', 'success');
    } else {
      showNotification('GIF copied to clipboard!', 'success');
    }

  } catch (error) {
    throw new Error('Failed to copy: ' + error.message);
  }
}

/**
 * Try to use native messaging host to copy GIF
 * Returns {success: boolean, error?: string}
 */
async function tryNativeMessaging(url) {
  try {
    // Send message to background script to use native messaging
    const response = await chrome.runtime.sendMessage({
      action: 'useNativeHost',
      url: url
    });

    return response;

  } catch (error) {
    console.log('Native messaging not available:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Fetch GIF from URL as Blob
 */
async function fetchGifAsBlob(url) {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const blob = await response.blob();

    // Verify it's actually a GIF
    if (!blob.type.includes('gif')) {
      console.warn('File type is not GIF:', blob.type);
      // Create a new blob with correct MIME type
      return new Blob([blob], { type: 'image/gif' });
    }

    return blob;

  } catch (error) {
    if (error.name === 'TypeError') {
      throw new Error('Network error or CORS issue');
    }
    throw error;
  }
}

/**
 * Copy Blob to clipboard using Clipboard API
 */
async function copyBlobToClipboard(blob) {
  try {
    // Try copying as GIF first
    const clipboardItem = new ClipboardItem({
      'image/gif': blob
    });

    await navigator.clipboard.write([clipboardItem]);
    return { asPng: false };

  } catch (error) {
    // If image/gif doesn't work, convert to PNG and try again
    // (Chrome on macOS doesn't support GIF in clipboard)
    console.warn('GIF clipboard not supported, converting to PNG...', error);

    try {
      const pngBlob = await convertGifToPng(blob);
      const clipboardItem = new ClipboardItem({
        'image/png': pngBlob
      });

      await navigator.clipboard.write([clipboardItem]);
      console.log('Successfully copied as PNG (first frame only)');
      return { asPng: true };

    } catch (pngError) {
      console.error('PNG fallback failed:', pngError);
      throw new Error('Failed to copy to clipboard: ' + pngError.message);
    }
  }
}

/**
 * Convert GIF blob to PNG blob (extracts first frame)
 * This is a fallback for systems that don't support GIF in clipboard
 */
async function convertGifToPng(gifBlob) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(gifBlob);

    img.onload = () => {
      try {
        // Create canvas and draw the image
        const canvas = document.createElement('canvas');
        canvas.width = img.naturalWidth || img.width;
        canvas.height = img.naturalHeight || img.height;

        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);

        // Convert canvas to PNG blob
        canvas.toBlob((pngBlob) => {
          URL.revokeObjectURL(url);
          if (pngBlob) {
            resolve(pngBlob);
          } else {
            reject(new Error('Failed to convert to PNG'));
          }
        }, 'image/png');

      } catch (error) {
        URL.revokeObjectURL(url);
        reject(error);
      }
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Failed to load image'));
    };

    img.src = url;
  });
}

/**
 * Show notification to user
 */
function showNotification(message, type = 'info') {
  // Create notification element
  const notification = document.createElement('div');
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 16px 24px;
    background-color: ${type === 'error' ? '#f44336' : '#4CAF50'};
    color: white;
    border-radius: 4px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    z-index: 2147483647;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 14px;
    max-width: 300px;
    animation: slideIn 0.3s ease-out;
  `;

  // Add animation
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideIn {
      from {
        transform: translateX(400px);
        opacity: 0;
      }
      to {
        transform: translateX(0);
        opacity: 1;
      }
    }
  `;
  document.head.appendChild(style);

  // Add to page
  document.body.appendChild(notification);

  // Remove after 3 seconds
  setTimeout(() => {
    notification.style.animation = 'slideIn 0.3s ease-out reverse';
    setTimeout(() => {
      notification.remove();
      style.remove();
    }, 300);
  }, 3000);
}
