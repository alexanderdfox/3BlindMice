# 3 Blind Mice - Multi-Mouse Triangulation

A sophisticated macOS application that enables multiple mice to control a single cursor through intelligent triangulation algorithms.

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
│   ├── cli/                    # Command-line interface
│   │   ├── 3blindmice.swift   # Main CLI version
│   │   └── 3blindmice_with_permissions.swift
│   └── gui/                    # Graphical interface (Xcode project)
│       └── ThreeBlindMice/     # SwiftUI application
├── scripts/                    # Build and utility scripts
│   ├── build_and_run.sh       # Build and launch GUI version
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
├── ThreeBlindMice.xcodeproj/  # Xcode project
├── ThreeBlindMice.xcworkspace/
├── Package.swift              # Swift Package Manager
└── README.md                  # This file
```

## 🚀 Quick Start

### GUI Version (Recommended)

1. **Build and Run**:
   ```bash
   ./scripts/build_and_run.sh
   ```

2. **Or Launch Existing Build**:
   ```bash
   ./scripts/run_release.sh
   ```

3. **Look for the 🐭 icon** in your menu bar and click it to control the application.

### CLI Version

1. **Build and Run**:
   ```bash
   ./scripts/build.sh
   ```

## 🔧 Installation

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later (for GUI version)
- Swift 5.9 or later

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd 3BlindMice
   ```

2. **Grant HID Permissions** (required for both versions):
   ```bash
   ./scripts/fix_permissions.sh
   ```

3. **Build and run**:
   ```bash
   ./scripts/build_and_run.sh
   ```

## 🎮 Usage

### GUI Version

1. **Launch**: Run the application and look for the 🐭 icon in your menu bar
2. **Control**: Click the menu bar icon to open the control panel
3. **Start**: Click "Start Triangulation" to begin multi-mouse control
4. **Monitor**: Watch the real-time display of connected mice and cursor position
5. **Stop**: Click "Stop Triangulation" to pause multi-mouse control

### CLI Version

1. **Run**: Execute the Swift file directly
2. **Connect Mice**: Plug in multiple mice
3. **Use**: Move any mouse to control the cursor
4. **Mode Switching**: Press 'M' to toggle between Individual and Fused modes
5. **Debug**: Press 'I' for individual positions, 'A' for active mouse
6. **Exit**: Press Ctrl+C to stop

## 🔒 Permissions

The application requires **Input Monitoring** permissions to access HID devices:

1. **System Preferences** → **Security & Privacy** → **Privacy**
2. **Input Monitoring** → Add **ThreeBlindMice.app**
3. **Restart** the application

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

- **GUI**: SwiftUI + AppKit for menu bar integration
- **CLI**: Pure Swift with IOKit for HID access
- **Core Logic**: Shared triangulation algorithms
- **Permissions**: TCC-compliant HID access

## 🛠️ Development

### Building from Source

1. **GUI Version**:
   ```bash
   xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release build
   ```

2. **CLI Version**:
   ```bash
   swift src/cli/3blindmice.swift
   ```

### Project Structure

- **Xcode Project**: `ThreeBlindMice.xcodeproj/`
- **Swift Package**: `Package.swift`
- **Source Code**: `src/` directory
- **Documentation**: `docs/` directory

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

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

**3 Blind Mice** - Making multi-mouse control intuitive and powerful! 🐭🐭🐭
