# Roadmap: Chrome Extension - Copy GIF

## Project Goal
Create a Chrome browser extension that adds an option to the context menu (right-click) allowing users to Copy GIFs to the clipboard (instead of just a single frame, as with the standard "Copy Image" feature).

---

## Phase 1: Project Setup

### 1.1 Initialize Project Structure
- [✓] Create project folder
- [✓] Create basic folder structure:
  ```
  gif-to-clipboard/
  ├── manifest.json
  ├── background.js
  ├── content.js
  ├── icons/
  │   ├── icon16.png
  │   ├── icon48.png
  │   └── icon128.png
  └── README.md
  ```

### 1.2 Configure manifest.json
- [✓] Create `manifest.json` file with Manifest V3 configuration
- [✓] Define basic metadata (name, version, description)
- [✓] Add permissions (`contextMenus`, `clipboardWrite`, `activeTab`)
- [✓] Configure background service worker
- [✓] Configure content scripts
- [✓] Add extension icons (can use placeholders temporarily)

### 1.3 Prepare Extension Icons
- [✓] Generate or download icons in sizes: 16x16, 48x48, 128x128
- [✓] Place icons in `icons/` folder

---

## Phase 2: Core Functionality Implementation

### 2.1 Background Script - Context Menu
**File: `background.js`**

- [✓] Add listener for `chrome.runtime.onInstalled`
- [✓] Create context menu using `chrome.contextMenus.create()`
- [✓] Configure menu to display on all elements (`contexts: ['all']`)
- [✓] Add handler for menu click (`chrome.contextMenus.onClicked`)
- [✓] Implement message passing to content script

**Features:**
- Create "Copy GIF" option in context menu
- Send message to content script with information about clicked element

### 2.2 Content Script - Finding GIFs
**File: `content.js`**

- [✓] Add listener for messages from background script (`chrome.runtime.onMessage`)
- [✓] Implement function to find clicked element on page
- [✓] Implement recursive DOM search function to find GIFs
- [✓] Validate if found element is a GIF (check for `.gif` in `src`)
- [✓] Handle different cases (img tag, background-image in CSS, picture element)

**Features:**
- Function `findGifInElement(element)` - searches element and its descendants
- Function `getAllImagesFromElement(element)` - returns all images
- Filter only GIFs from the list of found images

### 2.3 Content Script - Copy GIF to Clipboard
**File: `content.js`**

- [✓] Implement function to fetch GIF as Blob (`fetch()`)
- [✓] Implement function to copy to clipboard (`navigator.clipboard.write()`)
- [✓] Create `ClipboardItem` with appropriate MIME type
- [✓] Handle errors (CORS, permission denied, timeout)
- [✓] Add user notifications (success/error)

**Features:**
- Function `fetchGifAsBlob(url)` - fetches GIF from URL
- Function `copyBlobToClipboard(blob)` - copies Blob to clipboard
- Handle different formats (image/gif, web image/gif)

### 2.4 Native Messaging Host - Animated GIF Support
**Why needed:** Browser Clipboard API doesn't support animated GIFs on any platform (macOS, Windows, Linux). Native messaging allows us to use OS-level clipboard commands to preserve animation.

**File: `native-host/` directory**

#### Native Host Scripts:
- [ ] Create `native-host/` directory in project
- [ ] Create `copy-gif-host.py` - Python script for native messaging
- [ ] Implement message handling (receive GIF URL from extension)
- [ ] Implement file download logic in native host
- [ ] Implement macOS clipboard copy (using `osascript`)
- [ ] Implement Windows clipboard copy (using PowerShell)
- [ ] Implement Linux clipboard copy (using `xclip`)
- [ ] Add error handling and logging

#### Native Host Manifest:
- [ ] Create `com.copygif.host.json` manifest file
- [ ] Configure native host name and path
- [ ] Specify allowed extension IDs
- [ ] Set host type as "stdio"

#### Extension Updates:
- [ ] Add `nativeMessaging` permission to `manifest.json`
- [ ] Update `content.js` to detect if native host is available
- [ ] Implement fallback: try native host first, then Clipboard API
- [ ] Add function to send message to native host
- [ ] Handle native host responses and errors
- [ ] Update notifications based on copy method used

#### Installation Scripts:
- [ ] Create `install-native-host.sh` for macOS/Linux
- [ ] Create `install-native-host.bat` for Windows
- [ ] Scripts should copy native host to correct location
- [ ] Scripts should install manifest in browser's native messaging directory
- [ ] Add instructions to README.md

**Features:**
- Download GIF to temporary location
- Use OS-specific commands to copy file to clipboard (preserves animation)
- Auto-cleanup temporary files
- Cross-platform support (macOS, Windows, Linux)
- Graceful fallback to PNG if native host not installed

**Locations for Native Messaging Manifests:**
- **macOS Chrome:** `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/`
- **macOS Chromium:** `~/Library/Application Support/Chromium/NativeMessagingHosts/`
- **Windows Chrome:** `HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\`
- **Linux Chrome:** `~/.config/google-chrome/NativeMessagingHosts/`

---

## Phase 3: Local Testing

### 3.1 Load Extension in Developer Mode
- [ ] Open Chrome and navigate to `chrome://extensions/`
- [ ] Enable "Developer mode" (toggle in top right corner)
- [ ] Click "Load unpacked" and select project folder
- [ ] Verify extension appears in the list

### 3.2 Test Basic Functionality
- [ ] Test 1: Check if context menu displays
- [ ] Test 2: Find a page with animated GIF (e.g. giphy.com)
- [ ] Test 3: Right-click on element containing GIF
- [ ] Test 4: Select "Copy GIF" option
- [ ] Test 5: Paste GIF in another application (e.g. Gmail, Slack)
- [ ] Test 6: Verify GIF is animated after pasting

### 3.3 Test Edge Cases
- [ ] Test on element that does NOT contain a GIF
- [ ] Test on GIF from different domain (CORS)
- [ ] Test on very large GIF (>10MB)
- [ ] Test on GIF in `<picture>` element
- [ ] Test on GIF as CSS background-image
- [ ] Test functionality in different Chromium browsers (Brave, Edge)

### 3.4 Debugging
- [ ] Use Chrome DevTools for background script:
  - Click "Inspect views: background page" in `chrome://extensions/`
- [ ] Use Chrome DevTools for content script:
  - Standard DevTools on the page (F12)
  - Check Console tab for errors
- [ ] Add `console.log()` in key places
- [ ] Check "Errors" tab in `chrome://extensions/`

---

## Phase 4: Improvements and Polish

### 4.1 Dynamic Menu Display
- [ ] Modify code so menu only shows when element contains a GIF
- [ ] Use `chrome.contextMenus.update()` to dynamically change visibility
- [ ] Optimize performance (cache, debouncing)

### 4.2 User Experience
- [ ] Add icon to context menu option
- [ ] Add visual notifications (toast/notification) after copying
- [ ] Add loading indicator for large GIFs
- [ ] Add options in extension settings (optional)

### 4.3 Error Handling
- [ ] User-friendly error messages
- [ ] Fallback for cases when Clipboard API doesn't work
- [ ] Error logging (for potential debugging)
- [ ] Timeout for slow-loading GIFs

### 4.4 Optimization
- [ ] Limit depth of DOM traversal (performance)
- [ ] Limit GIF size for copying (e.g. 20MB max)
- [ ] Lazy loading for content script
- [ ] Code minification (optional)

---

## Phase 5: Preparation for Publication

### 5.1 Documentation
- [ ] Update README.md with:
  - Feature description
  - Screenshots of functionality
  - Installation instructions
  - List of known limitations
- [ ] Create CHANGELOG.md
- [ ] Add LICENSE (e.g. MIT)

### 5.2 Marketing Materials
- [ ] Prepare screenshots (1280x800 or 640x400)
- [ ] Record demo video (optional but recommended)
- [ ] Prepare promotional tiles:
  - Small tile: 440x280
  - Large tile: 920x680 (optional)
- [ ] Write description for Chrome Web Store (max 132 characters for short)

### 5.3 Final Testing
- [ ] Test on clean Chrome installation
- [ ] Test all functionality on different websites
- [ ] Check that there are no errors in console
- [ ] Code review (if possible)
- [ ] Verify compliance with Chrome Web Store policies

### 5.4 Prepare Package for Publication
- [ ] Remove development files (.git, node_modules, etc.)
- [ ] Verify manifest.json (correct versions, descriptions)
- [ ] Create ZIP with extension contents
- [ ] Verify package size (max 100MB for web store)

---

## Phase 6: Chrome Web Store Publication

### 6.1 Create Developer Account
- [ ] Go to [Chrome Web Store Developer Dashboard](https://chrome.google.com/webstore/devconsole/)
- [ ] Sign in with Google account
- [ ] Pay one-time registration fee ($5 USD)
- [ ] Verify account (if required)

### 6.2 Fill Out Publication Form
- [ ] Click "New Item" in Developer Dashboard
- [ ] Upload ZIP file with extension
- [ ] Fill out "Store listing" tab:
  - Detailed description
  - Category (Productivity)
  - Language (English)
  - Screenshots (minimum 1, maximum 5)
  - Small promotional tile (440x280)
  - Large promotional tile (optional, 920x680)
- [ ] Fill out "Privacy practices" tab:
  - Single purpose description
  - Permissions justification
  - Privacy policy URL (optional but recommended)
- [ ] Fill out "Distribution" tab:
  - Visibility (Public / Unlisted)
  - Regions (select countries)

### 6.3 Verification and Submit
- [ ] Check all fields
- [ ] Accept Terms of Service
- [ ] Click "Submit for review"
- [ ] Save draft before final submit (safety)

### 6.4 Post-Submission
- [ ] Wait for review (typically 1-3 days, may be longer)
- [ ] Monitor status in Developer Dashboard
- [ ] Respond to any feedback from review team
- [ ] After approval: verify functionality in store

---

## Phase 7: Post-Launch

### 7.1 Monitoring
- [ ] Check usage statistics in Developer Dashboard
- [ ] Monitor reviews and ratings
- [ ] Respond to user comments

### 7.2 Maintenance
- [ ] Collect user feedback
- [ ] Fix bugs reported by users
- [ ] Update when Chrome API changes
- [ ] Regular updates (security, new features)

### 7.3 Future Enhancements (Optional)
- [ ] Support for other formats (WEBP animations, APNG)
- [ ] Keyboard shortcuts
- [ ] Ability to select specific GIF when multiple exist
- [ ] Integration with popular services (Giphy, Tenor)
- [ ] Usage statistics (privacy-friendly)

---

## Required Resources

### Tools
- Google Chrome (latest version)
- Code editor (VS Code, WebStorm, etc.)
- Git (optional but recommended)
- Icon creation/editing tool (Figma, Photoshop, GIMP)

### Account and Fees
- Google account
- $5 USD - one-time Chrome Web Store Developer account fee

### Knowledge (to be acquired during development)
- JavaScript basics
- Chrome Extension API basics
- Async/Await basics
- Clipboard API basics

---

## Potential Challenges

### Technical
1. **CORS** - GIFs from other domains may require special permissions
   - Solution: Add `host_permissions` in manifest.json

2. **Clipboard API compatibility** - not all formats are supported
   - Solution: Fallback to `image/png` or custom web formats

3. **Performance** - searching deep DOM structures
   - Solution: Depth limits, caching, debouncing

4. **Different ways of embedding GIFs** - img, picture, CSS background
   - Solution: Handle different cases

### Business/Procedural
1. **Long review time** - can take up to a week
   - Solution: Patience, thorough form completion

2. **Rejection by Chrome Web Store** - possible rejection on first submit
   - Solution: Carefully read policies, respond to feedback

3. **Extension maintenance** - Chrome API updates
   - Solution: Subscribe to Chrome Developers newsletter

---

## Resources and Helpful Links

### Documentation
- [Chrome Extensions - Getting Started](https://developer.chrome.com/docs/extensions/mv3/getstarted/)
- [Chrome Extensions - Context Menus API](https://developer.chrome.com/docs/extensions/reference/contextMenus/)
- [MDN - Clipboard API](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API)
- [Chrome Web Store Developer Dashboard](https://chrome.google.com/webstore/devconsole/)

### Tools
- [Manifest V3 Migration Guide](https://developer.chrome.com/docs/extensions/mv3/intro/)
- [Extension Icon Generator](https://www.favicon-generator.org/)
- [Chrome Extension Source Viewer](https://robwu.nl/crxviewer/) - for analyzing other extensions

### Community
- [r/chrome_extensions](https://www.reddit.com/r/chrome_extensions/)
- [Stack Overflow - chrome-extension tag](https://stackoverflow.com/questions/tagged/google-chrome-extension)
