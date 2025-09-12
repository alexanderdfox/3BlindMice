# Cross-Platform Support

This document outlines the cross-platform implementation of 3 Blind Mice for macOS, Windows, Linux, and ChromeOS.

## 🎯 Platform Overview

| Platform | Status | GUI Support | CLI Support | HID API | Cursor Control |
|----------|--------|-------------|-------------|---------|----------------|
| **macOS** | ✅ Complete | SwiftUI Menu Bar | Swift + IOKit | IOKit HID | Core Graphics |
| **Windows** | ✅ Complete | Console Only | Swift + C++ | Raw Input API | Win32 SetCursorPos |
| **Linux** | ✅ Complete | Console Only | Swift + C | evdev Interface | X11 XTest |
| **ChromeOS** | ✅ Complete | Chrome Extension | Swift + C (Crostini) | Chrome APIs / evdev | Web APIs / X11 XTest |

## 🏗️ Architecture

### Shared Components

All platforms share the core triangulation logic implemented in Swift:

- **MultiMouseManager**: Core triangulation algorithms
- **Mouse Position Tracking**: Individual mouse coordinate management
- **Weighted Averaging**: Activity-based mouse weighting
- **Mode Switching**: Individual vs Fused control modes
- **Smoothing**: 60 FPS position smoothing

### Platform-Specific Components

#### macOS
- **Framework**: SwiftUI + AppKit
- **HID Access**: IOKit HID Manager
- **Permissions**: TCC (Transparency, Consent, and Control)
- **Build System**: Xcode + Swift Package Manager
- **Features**: Full GUI with menu bar integration

#### Windows
- **Framework**: Swift + C++ Bridge
- **HID Access**: Windows Raw Input API
- **Permissions**: UAC (User Account Control)
- **Build System**: CMake + Visual Studio
- **Features**: Console application with Windows API integration

#### Linux
- **Framework**: Swift + C Bridge
- **HID Access**: Linux evdev interface
- **Permissions**: udev rules + group membership
- **Build System**: CMake + GCC/Clang
- **Features**: Terminal application with X11 integration

#### ChromeOS
- **Framework**: Chrome Extension (JavaScript) + Swift + C Bridge (Crostini)
- **HID Access**: Chrome input API or evdev interface
- **Permissions**: Chrome extension permissions or udev rules
- **Build System**: Chrome Extension or CMake + GCC/Clang
- **Features**: Browser extension with web integration or Crostini native app

## 🔧 Implementation Details

### HID Device Access

#### macOS (IOKit)
```swift
import IOKit.hid

let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchingDict = [
    kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
    kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse
]
IOHIDManagerSetDeviceMatching(hidManager, matchingDict as CFDictionary)
```

#### Windows (Raw Input API)
```cpp
RAWINPUTDEVICE rid[1];
rid[0].usUsagePage = HID_USAGE_PAGE_GENERIC;
rid[0].usUsage = HID_USAGE_GENERIC_MOUSE;
rid[0].dwFlags = RIDEV_INPUTSINK;
rid[0].hwndTarget = hwnd;
RegisterRawInputDevices(rid, 1, sizeof(RAWINPUTDEVICE));
```

#### Linux (evdev)
```c
int fd = open("/dev/input/mouse0", O_RDONLY | O_NONBLOCK);
struct input_event event;
read(fd, &event, sizeof(event));
```

#### ChromeOS (Chrome Extension)
```javascript
// Monitor pointer events
document.addEventListener('pointermove', (event) => {
    const deviceId = event.pointerId || 'default';
    const deltaX = event.movementX || 0;
    const deltaY = event.movementY || 0;
    // Process input...
});
```

#### ChromeOS (Crostini)
```c
// Same as Linux evdev implementation
int fd = open("/dev/input/mouse0", O_RDONLY | O_NONBLOCK);
struct input_event event;
read(fd, &event, sizeof(event));
```

### Cursor Control

#### macOS (Core Graphics)
```swift
CGWarpMouseCursorPosition(position)
CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
```

#### Windows (Win32)
```cpp
SetCursorPos(x, y);
```

#### Linux (X11)
```c
XTestFakeMotionEvent(display, 0, x, y, CurrentTime);
XFlush(display);
```

#### ChromeOS (Web APIs)
```javascript
// Simulate cursor movement (limited in web context)
const cursor = document.createElement('div');
cursor.style.position = 'fixed';
cursor.style.left = x + 'px';
cursor.style.top = y + 'px';
document.body.appendChild(cursor);
```

#### ChromeOS (Crostini)
```c
// Same as Linux X11 implementation
XTestFakeMotionEvent(display, 0, x, y, CurrentTime);
XFlush(display);
```

## 🚀 Build Systems

### macOS
- **Primary**: Xcode project with Swift Package Manager
- **CLI**: Direct Swift compilation
- **Dependencies**: macOS SDK, IOKit framework

### Windows
- **Primary**: CMake with Visual Studio generator
- **Dependencies**: Windows SDK, Swift for Windows
- **Libraries**: user32.lib, kernel32.lib, advapi32.lib

### Linux
- **Primary**: CMake with Make generator
- **Dependencies**: Swift for Linux, X11, libevdev
- **Libraries**: libX11, libXtst, libevdev

### ChromeOS
- **Extension**: Chrome Extension (JavaScript)
- **Native**: CMake with Make generator (Crostini)
- **Dependencies**: Chrome browser or Swift for Linux, X11, libevdev
- **Libraries**: Chrome APIs or libX11, libXtst, libevdev

## 🔒 Permission Models

### macOS (TCC)
1. **Input Monitoring**: Required for HID access
2. **Setup**: System Preferences → Security & Privacy → Privacy
3. **App-specific**: Each app must be explicitly granted permission

### Windows (UAC)
1. **Administrator**: Required for Raw Input API access
2. **Setup**: Right-click → "Run as administrator"
3. **System-wide**: Administrator privileges for all HID operations

### Linux (udev + Groups)
1. **udev Rules**: Device access permissions
2. **Group Membership**: User must be in 'input' group
3. **Setup**: Install udev rules + add user to group

### ChromeOS (Extension + Crostini)
1. **Chrome Extension**: Input monitoring permissions
2. **Crostini**: Same as Linux (udev rules + group membership)
3. **Setup**: Grant extension permissions or install udev rules

## 📁 File Organization

```
3BlindMice/
├── src/                    # macOS CLI implementation
├── windows/               # Windows implementation
│   ├── src/
│   │   ├── swift/        # Swift source code
│   │   └── cpp/          # C++ Windows API wrapper
│   ├── CMakeLists.txt    # CMake configuration
│   └── *.bat             # Windows build scripts
├── linux/                # Linux implementation
│   ├── src/
│   │   ├── swift/        # Swift source code
│   │   └── c/            # C Linux API wrapper
│   ├── udev/             # udev rules
│   ├── CMakeLists.txt    # CMake configuration
│   └── *.sh              # Linux build scripts
├── chromeos/             # ChromeOS implementation
│   ├── extension/        # Chrome Extension
│   │   ├── manifest.json # Extension manifest
│   │   ├── background.js # Service worker
│   │   ├── content.js    # Content script
│   │   ├── popup.html    # Extension popup
│   │   └── icons/        # Extension icons
│   ├── src/
│   │   ├── swift/        # Swift source code (Crostini)
│   │   └── c/            # C Linux API wrapper (Crostini)
│   ├── CMakeLists.txt    # CMake configuration (Crostini)
│   └── *.sh              # ChromeOS build scripts
└── ThreeBlindMice/       # macOS GUI (Xcode project)
```

## 🧪 Testing

### Cross-Platform Testing

Each platform should be tested with:

1. **Multiple Mice**: USB and PS/2 mice
2. **Permission Scenarios**: With and without proper permissions
3. **Mode Switching**: Individual vs Fused modes
4. **Edge Cases**: No mice, single mouse, many mice
5. **Performance**: Smooth cursor movement, no lag

### Platform-Specific Testing

#### macOS
- **GUI Integration**: Menu bar icon and controls
- **Permission Flow**: TCC permission requests
- **Xcode Build**: Debug and Release configurations

#### Windows
- **Administrator Mode**: UAC elevation
- **Visual Studio**: Debug and Release builds
- **DLL Dependencies**: Swift runtime libraries

#### Linux
- **udev Rules**: Device access after installation
- **Group Membership**: Input group functionality
- **X11 Integration**: Cursor control across displays

#### ChromeOS
- **Chrome Extension**: Extension loading and permissions
- **Crostini Environment**: Linux container functionality
- **Web APIs**: Browser-based input handling
- **X11 Integration**: Cursor control in Crostini

## 🐛 Troubleshooting

### Common Issues

#### Permission Denied
- **macOS**: Check Input Monitoring permissions
- **Windows**: Run as administrator
- **Linux**: Check udev rules and group membership

#### No Mice Detected
- **macOS**: Verify IOKit HID Manager initialization
- **Windows**: Check Raw Input API registration
- **Linux**: Verify evdev device enumeration
- **ChromeOS**: Check Chrome extension permissions or Crostini device access

#### Cursor Not Moving
- **macOS**: Check Core Graphics permissions
- **Windows**: Verify SetCursorPos calls
- **Linux**: Check X11 display connection
- **ChromeOS**: Check web API limitations or X11 connection in Crostini

### Debug Tools

#### macOS
```bash
# Check permissions
./scripts/test_permissions.sh

# Debug HID access
log stream --predicate 'subsystem == "com.apple.kernel.hid"'
```

#### Windows
```cmd
# Check Raw Input registration
# Use Windows Event Viewer for HID events
```

#### Linux
```bash
# Check device access
ls -la /dev/input/

# Test evdev access
sudo cat /dev/input/mouse0

# Check X11 connection
echo $DISPLAY
```

#### ChromeOS
```bash
# Crostini (same as Linux)
ls -la /dev/input/
sudo cat /dev/input/mouse0
echo $DISPLAY
```

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

## 🔮 Future Enhancements

### Planned Features

1. **Unified Build System**: Single CMake configuration for all platforms
2. **Cross-Platform GUI**: Electron or similar for consistent UI
3. **Package Managers**: Homebrew, Chocolatey, apt packages
4. **CI/CD**: Automated builds for all platforms
5. **Documentation**: Platform-specific setup guides

### Technical Improvements

1. **Shared Core Library**: Common triangulation logic as shared library
2. **Plugin Architecture**: Platform-specific HID implementations
3. **Configuration**: Cross-platform settings management
4. **Logging**: Unified logging system across platforms
5. **Testing**: Automated cross-platform test suite

---

**Cross-Platform Support** - Bringing multi-mouse control to every platform! 🐭🪟🐧🌐
