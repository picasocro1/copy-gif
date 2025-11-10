// Background service worker for Copy GIF extension

const NATIVE_HOST_NAME = 'com.copygif.host';

// Create context menu when extension is installed or updated
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'copy-gif',
    title: 'Copy GIF',
    contexts: ['image', 'link']  // Show on images and links only
  });

  console.log('Copy GIF context menu created');
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'copy-gif') {
    // Check if we have a direct URL from the context menu
    const url = info.srcUrl || info.linkUrl;

    if (url) {
      // Check if the URL looks like a GIF before proceeding
      if (isGifUrl(url)) {
        // We have a direct GIF URL, send it to content script
        chrome.tabs.sendMessage(tab.id, {
          action: 'copyGif',
          directUrl: url,
          frameId: info.frameId
        }).catch(error => {
          console.error('Error sending message to content script:', error);
        });
      } else {
        // Not a GIF URL, but still try coordinate-based detection
        // (in case the clicked element contains a GIF child)
        chrome.tabs.sendMessage(tab.id, {
          action: 'copyGif',
          frameId: info.frameId,
          x: info.pageX || 0,
          y: info.pageY || 0
        }).catch(error => {
          console.error('Error sending message to content script:', error);
        });
      }
    } else {
      // Fallback to coordinate-based detection
      chrome.tabs.sendMessage(tab.id, {
        action: 'copyGif',
        frameId: info.frameId,
        x: info.pageX || 0,
        y: info.pageY || 0
      }).catch(error => {
        console.error('Error sending message to content script:', error);
      });
    }
  }
});

/**
 * Check if URL looks like a GIF file
 */
function isGifUrl(url) {
  if (!url) return false;

  // Remove query parameters and fragments for checking
  const urlWithoutParams = url.split('?')[0].split('#')[0];

  // Check if URL ends with .gif (case insensitive)
  return /\.gif$/i.test(urlWithoutParams);
}

// Handle messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'useNativeHost') {
    // Use native messaging to copy GIF
    useNativeHost(message.url)
      .then(result => sendResponse(result))
      .catch(error => sendResponse({ success: false, error: error.message }));

    return true; // Keep message channel open for async response
  }
});

/**
 * Use native messaging host to copy GIF
 */
async function useNativeHost(url) {
  return new Promise((resolve, reject) => {
    try {
      // Connect to native messaging host
      const port = chrome.runtime.connectNative(NATIVE_HOST_NAME);

      // Handle response from native host
      port.onMessage.addListener((response) => {
        console.log('Native host response:', response);

        if (response.success) {
          resolve({ success: true, method: 'native' });
        } else {
          resolve({ success: false, error: response.error || 'Unknown error' });
        }

        port.disconnect();
      });

      // Handle errors
      port.onDisconnect.addListener(() => {
        const error = chrome.runtime.lastError;

        if (error) {
          console.error('Native host disconnected with error:', error);
          resolve({
            success: false,
            error: `Native host not available: ${error.message}`
          });
        }
      });

      // Send message to native host
      port.postMessage({
        action: 'copyGif',
        url: url
      });

    } catch (error) {
      console.error('Error connecting to native host:', error);
      resolve({
        success: false,
        error: `Failed to connect to native host: ${error.message}`
      });
    }
  });
}
