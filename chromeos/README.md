# 3 Blind Mice - ChromeOS Implementation

This folder contains the ChromeOS-specific implementation of the 3 Blind Mice multi-mouse triangulation system.

## 🌐 ChromeOS Features

- **Chrome Extension**: Browser-based multi-mouse control
- **Native App Support**: Crostini Linux environment compatibility
- **Web APIs**: Modern web technologies for input handling
- **Security Model**: ChromeOS security and permission system
- **Cross-Platform**: Works on Chromebooks and ChromeOS devices

## 🚀 Quick Start

### Prerequisites

- ChromeOS device (Chromebook, Chromebox, etc.)
- Chrome browser (latest version)
- Developer mode enabled (for native app)
- Crostini enabled (for Linux app support)

### Installation Options

#### Option 1: Chrome Extension (Recommended)

1. **Enable Developer Mode**:
   - Go to Settings → About Chrome OS
   - Click "Additional details"
   - Enable "Developer mode"

2. **Load Extension**:
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked" and select the `chromeos/extension` folder

3. **Grant Permissions**:
   - Allow input monitoring permissions when prompted
   - Grant access to input devices

#### Option 2: Native Linux App (Crostini)

1. **Enable Crostini**:
   - Go to Settings → Linux (Beta)
   - Enable Linux development environment

2. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install swift libevdev-dev cmake build-essential
   ```

3. **Build and Run**:
   ```bash
   cd chromeos
   ./build.sh
   ./run.sh
   ```

## 🔧 Technical Details

### Architecture

ChromeOS offers multiple implementation approaches:

#### Chrome Extension Approach
- **JavaScript Core**: Multi-mouse triangulation in JavaScript
- **Web APIs**: Pointer Events API for mouse input
- **Chrome APIs**: chrome.input API for device access
- **Background Scripts**: Service worker for continuous operation
- **Content Scripts**: Page interaction and cursor control

#### Native Linux App (Crostini)
- **Swift Core**: Same Swift implementation as Linux
- **evdev Interface**: Linux evdev for device access
- **X11 Integration**: Cursor control through X11
- **Container Environment**: Runs in Crostini Linux container

### ChromeOS-Specific Features

- **Security Sandbox**: ChromeOS security model compliance
- **Permission System**: Chrome extension permissions
- **Device Access**: Limited but functional input device access
- **Web Integration**: Works with web applications
- **Cross-Device**: Syncs across ChromeOS devices

## 📁 File Structure

```
chromeos/
├── extension/                 # Chrome Extension
│   ├── manifest.json         # Extension manifest
│   ├── background.js          # Service worker
│   ├── content.js            # Content script
│   ├── popup.html            # Extension popup
│   ├── popup.js              # Popup functionality
│   └── icons/                # Extension icons
├── src/
│   ├── swift/                # Swift source code (Crostini)
│   │   ├── main.swift        # Main application entry
│   │   └── MultiMouseManager.swift
│   └── c/                    # C Linux API wrapper (Crostini)
│       ├── evdev_manager.c
│       └── evdev_manager.h
├── manifest/                 # ChromeOS app manifest
│   └── app.json              # ChromeOS app configuration
├── CMakeLists.txt            # CMake build configuration (Crostini)
├── build.sh                  # Build script (Crostini)
├── run.sh                    # Run script (Crostini)
├── package.sh                # Package extension
└── README.md                 # This file
```

## 🎮 Usage

### Chrome Extension

1. **Launch**: Click the 🐭 icon in Chrome toolbar
2. **Control**: Use the popup interface to control triangulation
3. **Start**: Click "Start Triangulation" to begin
4. **Monitor**: Watch real-time mouse position updates
5. **Stop**: Click "Stop Triangulation" to pause

### Native Linux App (Crostini)

1. **Run**: Execute `./run.sh` in terminal
2. **Connect Mice**: Plug in multiple mice
3. **Use**: Move any mouse to control the cursor
4. **Mode Switching**: Press 'M' to toggle modes
5. **Exit**: Press Ctrl+C to stop

## 🔒 Permissions

### Chrome Extension Permissions

The extension requires these permissions in `manifest.json`:

```json
{
  "permissions": [
    "input",
    "activeTab",
    "storage"
  ],
  "host_permissions": [
    "<all_urls>"
  ]
}
```

### Crostini Permissions

Same as Linux implementation:
1. **Install udev rules**: `sudo ./install.sh`
2. **Add user to input group**: `sudo usermod -a -G input $USER`
3. **Logout and login** to apply group changes

## 🛠️ Development

### Chrome Extension Development

1. **Load Extension**:
   ```bash
   # Package extension
   ./package.sh
   ```

2. **Test in Chrome**:
   - Go to `chrome://extensions/`
   - Enable "Developer mode"
   - Load unpacked extension

3. **Debug**:
   - Use Chrome DevTools
   - Check extension console logs
   - Monitor background script execution

### Crostini Development

1. **Enable Crostini**:
   - Settings → Linux (Beta) → Enable

2. **Install Development Tools**:
   ```bash
   sudo apt install swift cmake build-essential
   ```

3. **Build**:
   ```bash
   ./build.sh
   ```

## 🐛 Troubleshooting

### Common Issues

#### Extension Not Loading
- **Check**: Developer mode enabled
- **Verify**: Extension manifest is valid
- **Debug**: Check Chrome extension console

#### No Mice Detected
- **Extension**: Check input permissions
- **Crostini**: Verify udev rules and group membership
- **Hardware**: Ensure mice are properly connected

#### Permission Denied
- **Extension**: Grant input monitoring permissions
- **Crostini**: Run with proper user permissions
- **ChromeOS**: Check device security settings

### Debug Tools

#### Chrome Extension
```javascript
// Check extension permissions
chrome.permissions.getAll((permissions) => {
  console.log('Extension permissions:', permissions);
});

// Monitor input events
chrome.input.onInputEvent.addListener((event) => {
  console.log('Input event:', event);
});
```

#### Crostini
```bash
# Check device access
ls -la /dev/input/

# Test evdev access
sudo cat /dev/input/mouse0

# Check X11 connection
echo $DISPLAY
```

## 🔮 ChromeOS-Specific Considerations

### Security Model

- **Sandboxing**: ChromeOS runs apps in secure sandboxes
- **Permissions**: Granular permission system
- **Verified Boot**: System integrity protection
- **Guest Mode**: Limited functionality in guest mode

### Hardware Limitations

- **USB Access**: Limited USB device access in some modes
- **Input Devices**: May require specific ChromeOS input handling
- **Display**: Multiple display support varies by device

### Performance

- **Web APIs**: JavaScript performance for real-time input
- **Crostini**: Container overhead for native apps
- **Battery**: Power management considerations

## 📄 License

This project is licensed under the MIT License - see the main `LICENSE` file for details.

---

**3 Blind Mice ChromeOS** - Multi-mouse control for Chromebooks! 🐭🌐
