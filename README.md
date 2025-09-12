# 3 Blind Mice - Multi-Mouse Triangulation

A sophisticated cross-platform application that enables multiple mice to control a single cursor through intelligent triangulation algorithms. Available for macOS, Windows, Linux, and ChromeOS.

## 🎯 Features

- **Multi-Mouse Support**: Connect and use multiple mice simultaneously
- **Individual Mouse Coordinates**: Track each mouse's position separately
- **Dual Control Modes**: Switch between fused triangulation and individual mouse control
- **Enhanced Triangulation**: Weighted averaging, activity tracking, and smoothing
- **System Tray Integration**: Clean menu bar interface with mouse emoji icon
- **Real-time UI**: Live display of connected mice and cursor position
- **Permission Handling**: User-friendly guidance for HID permissions
- **Custom Emoji Support**: Assign personalized emojis to each mouse for easy identification
- **Custom Cursor Display**: Each mouse shows its assigned emoji as the actual system cursor
- **Dual Interface**: Both command-line and graphical versions available

## 📁 Project Structure

```
3BlindMice/
├── src/
│   ├── cli/                    # Command-line interface (macOS)
│   │   ├── 3blindmice.swift   # Main CLI version
│   │   └── 3blindmice_with_permissions.swift
│   └── gui/                    # Graphical interface (macOS Xcode project)
│       └── ThreeBlindMice/     # SwiftUI application
├── windows/                    # Windows implementation
│   ├── src/
│   │   ├── swift/             # Swift source code
│   │   └── cpp/               # C++ Windows API wrapper
│   ├── CMakeLists.txt         # CMake build configuration
│   ├── build.bat              # Windows build script
│   └── run.bat                # Windows run script
├── linux/                     # Linux implementation
│   ├── src/
│   │   ├── swift/             # Swift source code
│   │   └── c/                 # C Linux API wrapper
│   ├── udev/                  # udev rules for device access
│   ├── CMakeLists.txt         # CMake build configuration
│   ├── build.sh               # Linux build script
│   ├── run.sh                 # Linux run script
│   └── install.sh             # Linux installation script
├── chromeos/                  # ChromeOS implementation
│   ├── extension/             # Chrome Extension
│   │   ├── manifest.json      # Extension manifest
│   │   ├── background.js      # Service worker
│   │   ├── content.js         # Content script
│   │   ├── popup.html         # Extension popup
│   │   ├── popup.js           # Popup functionality
│   │   └── icons/             # Extension icons
│   ├── src/
│   │   ├── swift/             # Swift source code (Crostini)
│   │   └── c/                 # C Linux API wrapper (Crostini)
│   ├── CMakeLists.txt         # CMake build configuration (Crostini)
│   ├── build.sh               # Build script (Crostini)
│   ├── run.sh                 # Run script (Crostini)
│   └── package.sh             # Package extension
├── scripts/                   # Build and utility scripts (macOS)
│   ├── build_and_run.sh      # Build and launch GUI version
│   ├── run_release.sh         # Launch existing release build
│   ├── test_permissions.sh    # Check app permissions
│   ├── fix_permissions.sh     # Guide through permission setup
│   ├── generate_icon.sh       # Generate app icons
│   ├── install_icons.sh       # Install icons to Xcode project
│   └── build.sh               # Build CLI version
├── docs/                      # Documentation
│   ├── USAGE.md              # Use cases and scenarios
│   ├── TRIANGULATION_ENHANCEMENTS.md
│   ├── HID_PERMISSIONS_GUIDE.md
│   └── XCODE_README.md
├── assets/
│   └── icons/                 # App icons
├── ThreeBlindMice.xcodeproj/  # Xcode project (macOS)
├── ThreeBlindMice.xcworkspace/
├── Package.swift              # Swift Package Manager
└── README.md                  # This file
```

## 🚀 Quick Start

### macOS (Original)

#### GUI Version (Recommended)
1. **Build and Run**:
   ```bash
   ./scripts/build_and_run.sh
   ```

2. **Or Launch Existing Build**:
   ```bash
   ./scripts/run_release.sh
   ```

3. **Look for the 🐭 icon** in your menu bar and click it to control the application.

#### CLI Version
1. **Build and Run**:
   ```bash
   ./scripts/build.sh
   ```

### Windows

1. **Prerequisites**: Install Visual Studio 2022, Swift for Windows, and CMake
2. **Build**:
   ```cmd
   cd windows
   build.bat
   ```
3. **Run**:
   ```cmd
   run.bat
   ```

### Linux

1. **Prerequisites**: Install Swift, X11 dev libraries, libevdev, and CMake
2. **Build**:
   ```bash
   cd linux
   ./build.sh
   ```
3. **Install** (for proper permissions):
   ```bash
   sudo ./install.sh
   ```
4. **Run**:
   ```bash
   ./run.sh
   ```

### ChromeOS

#### Option 1: Chrome Extension (Recommended)
1. **Prerequisites**: ChromeOS device with Chrome browser
2. **Package Extension**:
   ```bash
   cd chromeos
   ./package.sh
   ```
3. **Install**: Load unpacked extension in Chrome
4. **Use**: Click 🐭 icon in toolbar

#### Option 2: Native Linux App (Crostini)
1. **Prerequisites**: Enable Crostini, install Swift and dependencies
2. **Build**:
   ```bash
   cd chromeos
   ./build.sh
   ```
3. **Run**:
   ```bash
   ./run.sh
   ```

## 🔧 Installation

### Prerequisites

#### macOS
- macOS 13.0 or later
- Xcode 15.0 or later (for GUI version)
- Swift 5.9 or later

#### Windows
- Windows 10/11
- Visual Studio 2022 or later
- Swift for Windows (Swift 5.9+)
- CMake 3.20+

#### Linux
- Linux (Ubuntu 20.04+, Fedora 35+, or similar)
- Swift 5.9+ for Linux
- X11 development libraries
- evdev development libraries
- CMake 3.20+
- GCC/Clang compiler

#### ChromeOS
- ChromeOS device (Chromebook, Chromebox, etc.)
- Chrome browser (latest version)
- Developer mode enabled (for native app)
- Crostini enabled (for Linux app support)
- Swift 5.9+ for Linux (Crostini)
- X11 and evdev libraries (Crostini)

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd 3BlindMice
   ```

2. **Platform-specific setup**:

   **macOS**: Grant HID Permissions
   ```bash
   ./scripts/fix_permissions.sh
   ```

   **Windows**: Open Developer Command Prompt and run:
   ```cmd
   cd windows
   build.bat
   ```

   **Linux**: Install dependencies and build:
   ```bash
   cd linux
   ./build.sh
   sudo ./install.sh
   ```

   **ChromeOS**: Package extension or build native app:
   ```bash
   cd chromeos
   ./package.sh  # For Chrome Extension
   # OR
   ./build.sh    # For Crostini native app
   ```

## 🎮 Usage

### macOS GUI Version

1. **Launch**: Run the application and look for the 🐭 icon in your menu bar
2. **Control**: Click the menu bar icon to open the control panel
3. **Start**: Click "Start Triangulation" to begin multi-mouse control
4. **Monitor**: Watch the real-time display of connected mice and cursor position
5. **Stop**: Click "Stop Triangulation" to pause multi-mouse control

### Cross-Platform CLI Version

1. **Run**: Execute the platform-specific executable
2. **Connect Mice**: Plug in multiple mice
3. **Use**: Move any mouse to control the cursor
4. **Mode Switching**: Press 'M' to toggle between Individual and Fused modes
5. **Debug**: Press 'I' for individual positions, 'A' for active mouse
6. **Exit**: Press Ctrl+C to stop

### Platform-Specific Notes

- **macOS**: Full GUI support with menu bar integration
- **Windows**: Console application with Windows Raw Input API
- **Linux**: Terminal application with evdev interface and X11 cursor control
- **ChromeOS**: Chrome Extension with web APIs or Crostini native app

## 🔒 Permissions

The application requires permissions to access HID devices on each platform:

### macOS
1. **System Preferences** → **Security & Privacy** → **Privacy**
2. **Input Monitoring** → Add **ThreeBlindMice.app**
3. **Restart** the application

### Windows
1. **Run as Administrator** (right-click → "Run as administrator")
2. **Allow UAC prompts** when they appear
3. **Antivirus**: Add exception if blocked

### Linux
1. **Install udev rules**: `sudo ./install.sh`
2. **Add user to input group**: `sudo usermod -a -G input $USER`
3. **Logout and login** to apply group changes

### ChromeOS
1. **Chrome Extension**: Grant input monitoring permissions when prompted
2. **Crostini Native**: Same as Linux (udev rules + input group)
3. **Developer Mode**: Enable for native app installation

For detailed troubleshooting, see `docs/HID_PERMISSIONS_GUIDE.md`.

## 🎯 Use Cases

- **Collaborative Design**: Multiple designers working on shared content
- **Gaming**: Multi-player control of shared game elements
- **Accessibility**: Caregivers assisting users with limited mobility
- **Education**: Multiple students interacting with shared content
- **Precision Work**: Multiple input devices for specialized tasks

For detailed use cases, see `docs/USAGE.md`.

## 🔬 Technical Details

### Enhanced Triangulation Algorithm

- **Weighted Averaging**: Active mice have more influence
- **Activity Tracking**: Monitors mouse usage patterns
- **Position Smoothing**: 60 FPS smoothing eliminates jitter
- **Boundary Clamping**: Ensures cursor stays within screen bounds
- **Individual Coordinates**: Each mouse maintains its own position
- **Dual Modes**: Switch between fused and individual control

For technical details, see `docs/TRIANGULATION_ENHANCEMENTS.md`.

### Architecture

#### macOS
- **GUI**: SwiftUI + AppKit for menu bar integration
- **CLI**: Pure Swift with IOKit for HID access
- **Core Logic**: Shared triangulation algorithms
- **Permissions**: TCC-compliant HID access

#### Windows
- **Core**: Swift with C++ Windows API bridge
- **HID**: Windows Raw Input API for multi-mouse detection
- **Cursor Control**: Win32 SetCursorPos for positioning
- **Build**: CMake with Visual Studio integration

#### Linux
- **Core**: Swift with C evdev bridge
- **HID**: Linux evdev interface for device access
- **Cursor Control**: X11 XTest for cursor positioning
- **Build**: CMake with GCC/Clang support

#### ChromeOS
- **Extension**: JavaScript + Chrome APIs
- **Native**: Swift + C evdev bridge (Crostini)
- **HID**: Chrome input API or evdev interface
- **Cursor Control**: Web APIs or X11 XTest
- **Build**: Chrome Extension or CMake (Crostini)

## 🛠️ Development

### Building from Source

#### macOS
1. **GUI Version**:
   ```bash
   xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release build
   ```

2. **CLI Version**:
   ```bash
   swift src/cli/3blindmice.swift
   ```

#### Windows
```cmd
cd windows
cmake -B build -S .
cmake --build build --config Release
```

#### Linux
```bash
cd linux
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

#### ChromeOS
```bash
# Chrome Extension
cd chromeos
./package.sh

# Crostini Native App
cd chromeos
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

### Project Structure

- **macOS**: Xcode project (`ThreeBlindMice.xcodeproj/`)
- **Windows**: CMake project (`windows/CMakeLists.txt`)
- **Linux**: CMake project (`linux/CMakeLists.txt`)
- **ChromeOS**: Chrome Extension (`chromeos/extension/`) + CMake project (`chromeos/CMakeLists.txt`)
- **Swift Package**: `Package.swift` (macOS)
- **Source Code**: Platform-specific directories
- **Documentation**: `docs/` directory

## 📄 License

This project is licensed under the BSD License - see the `LICENSE` file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the documentation in `docs/`
2. Review permission setup in `docs/HID_PERMISSIONS_GUIDE.md`
3. Test with `scripts/test_permissions.sh`

---

**3 Blind Mice** - Cross-platform multi-mouse control for macOS, Windows, Linux, and ChromeOS! 🐭🪟🐧🌐
