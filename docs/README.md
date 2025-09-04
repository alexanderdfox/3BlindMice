# 3 Blind Mice - Multi-Mouse Triangulation

A macOS application that fuses input from multiple mice to control a single cursor, implementing a triangulation-based approach to multi-mouse control.

## Features

- **Multi-Mouse Support**: Detects and processes input from multiple connected mice
- **Triangulation Algorithm**: Fuses mouse movements using averaging to create a unified cursor control
- **System Tray Interface**: Runs in the menu bar with a beautiful SwiftUI control panel
- **Start/Stop Control**: Easily enable or disable the triangulation feature
- **Real-time Status**: Monitor connected mice and cursor position

## Versions

### Command Line Version
- File: `3blindmice.swift`
- Run with: `swift 3blindmice.swift`
- Simple command-line interface

### Graphical System Tray Version
- File: `3BlindMiceApp.swift`
- Modern SwiftUI interface
- Runs in the menu bar (system tray)
- Interactive control panel

## Installation & Usage

### Quick Start (Graphical Version)
```bash
# Make build script executable (if not already)
chmod +x build.sh

# Build and run
./build.sh
```

### Manual Build
```bash
# Build the application
swift build -c release

# Run the application
.build/release/ThreeBlindMice
```

### Command Line Version
```bash
# Run the original command-line version
swift 3blindmice.swift
```

## How It Works

1. **Device Detection**: The application scans for all connected HID mouse devices
2. **Input Processing**: Captures movement deltas from each mouse
3. **Triangulation**: Averages the movement vectors from all mice
4. **Cursor Control**: Applies the fused movement to the system cursor

## System Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- Multiple USB mice (or trackpads) connected

## Usage Instructions

1. **Connect Multiple Mice**: Plug in 2 or more USB mice to your Mac
2. **Launch Application**: Run the build script or compiled application
3. **Access Control Panel**: Click the mouse icon in your menu bar
4. **Start Triangulation**: Click "Start Triangulation" in the control panel
5. **Control Cursor**: Move any of the connected mice to control the unified cursor
6. **Stop When Done**: Click "Stop Triangulation" or "Quit" to exit

## Technical Details

- Uses IOKit HID framework for device detection
- Implements CoreGraphics for cursor positioning
- SwiftUI for the modern user interface
- Runs as a background application (LSUIElement)

## Troubleshooting

- **No mice detected**: Ensure mice are properly connected via USB
- **Permission issues**: Grant accessibility permissions if prompted
- **Cursor not moving**: Check that triangulation is active in the control panel

## License

See LICENSE file for details.

## Contributing

Feel free to submit issues and enhancement requests!
