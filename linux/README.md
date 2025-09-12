# 3 Blind Mice - Linux Implementation

This folder contains the Linux-specific implementation of the 3 Blind Mice multi-mouse triangulation system.

## 🐧 Linux Features

- **evdev Support**: Uses Linux evdev interface for multi-mouse detection
- **Cross-Platform Swift**: Swift code adapted for Linux platform
- **C Bridge**: Native Linux APIs wrapped for Swift compatibility
- **X11 Integration**: X11 window system integration for cursor control
- **SystemD Support**: Optional systemd service integration

## 🚀 Quick Start

### Prerequisites

- Linux (Ubuntu 20.04+, Fedora 35+, or similar)
- Swift 5.9+ for Linux
- X11 development libraries
- evdev development libraries
- CMake 3.20+
- GCC/Clang compiler

### Installation

1. **Install dependencies (Ubuntu/Debian)**:
   ```bash
   sudo apt update
   sudo apt install swift libx11-dev libevdev-dev cmake build-essential
   ```

2. **Install dependencies (Fedora/RHEL)**:
   ```bash
   sudo dnf install swift-lang libX11-devel libevdev-devel cmake gcc
   ```

3. **Build the project**:
   ```bash
   cd linux
   mkdir build && cd build
   cmake ..
   make -j$(nproc)
   ```

4. **Run the application**:
   ```bash
   ./ThreeBlindMice
   ```

## 🔧 Technical Details

### Architecture

- **Swift Core**: Main triangulation logic in Swift
- **C Bridge**: Linux evdev and X11 API wrapper
- **evdev Integration**: Direct access to input devices
- **X11 Integration**: Native cursor control
- **CMake Build**: Cross-platform build system

### Linux-Specific Features

- **evdev Interface**: Direct access to multiple mice
- **X11 Cursor Control**: Native cursor positioning
- **Device Detection**: Automatic mouse device discovery
- **Permission Handling**: udev rules for device access
- **System Integration**: Optional systemd service

## 📁 File Structure

```
linux/
├── src/
│   ├── swift/              # Swift source code
│   │   ├── main.swift      # Main application entry
│   │   └── MultiMouseManager.swift
│   └── c/                  # C Linux API wrapper
│       ├── evdev_manager.c
│       ├── evdev_manager.h
│       └── x11_cursor.c
├── CMakeLists.txt          # CMake build configuration
├── build.sh                # Linux build script
├── run.sh                  # Linux run script
├── install.sh              # Installation script
├── udev/                   # udev rules for device access
│   └── 99-threeblindmice.rules
└── README.md               # This file
```

## 🎮 Usage

### GUI Version

1. **Launch**: Run `./ThreeBlindMice`
2. **Terminal Interface**: Use keyboard commands for control
3. **Start**: Press 'S' to start triangulation
4. **Stop**: Press 'Q' to quit

### CLI Version

1. **Run**: Execute `./ThreeBlindMice` from terminal
2. **Connect Mice**: Plug in multiple mice
3. **Use**: Move any mouse to control the cursor
4. **Exit**: Press Ctrl+C to stop

## 🔒 Permissions

Linux requires proper permissions for input device access:

### Method 1: udev Rules (Recommended)

1. **Install udev rules**:
   ```bash
   sudo cp udev/99-threeblindmice.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

2. **Add user to input group**:
   ```bash
   sudo usermod -a -G input $USER
   ```

3. **Logout and login** to apply group changes

### Method 2: Run as Root (Not Recommended)

```bash
sudo ./ThreeBlindMice
```

## 🛠️ Development

### Building from Source

1. **Clone and navigate**:
   ```bash
   git clone <repository-url>
   cd 3BlindMice/linux
   ```

2. **Install dependencies**:
   ```bash
   ./install.sh
   ```

3. **Build**:
   ```bash
   ./build.sh
   ```

### CMake Configuration

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**: Check udev rules and user groups
2. **Missing Libraries**: Install development packages
3. **X11 Errors**: Ensure X11 is running and accessible
4. **Device Not Found**: Check device permissions in `/dev/input/`

### Debug Mode

Run with verbose output:
```bash
RUST_LOG=debug ./ThreeBlindMice
```

### Check Device Access

```bash
# List input devices
ls -la /dev/input/

# Check device permissions
ls -la /dev/input/mouse*

# Test device access
sudo cat /dev/input/mouse0
```

## 🔧 Advanced Configuration

### Custom Device Selection

Edit `src/c/evdev_manager.c` to specify custom device paths:

```c
static const char* mouse_devices[] = {
    "/dev/input/mouse0",
    "/dev/input/mouse1",
    "/dev/input/event0",
    NULL
};
```

### X11 Display Configuration

Set display for remote X11:
```bash
export DISPLAY=:0.0
./ThreeBlindMice
```

## 📄 License

This project is licensed under the MIT License - see the main `LICENSE` file for details.

---

**3 Blind Mice Linux** - Multi-mouse control for Linux! 🐭🐧
