# 3 Blind Mice - Windows Implementation

This folder contains the Windows-specific implementation of the 3 Blind Mice multi-mouse triangulation system.

## 🪟 Windows Features

- **Win32 HID Support**: Uses Windows Raw Input API for multi-mouse detection
- **Cross-Platform Swift**: Swift code adapted for Windows platform
- **C++ Bridge**: Native Windows APIs wrapped for Swift compatibility
- **Visual Studio Support**: Complete Visual Studio project files

## 🚀 Quick Start

### Prerequisites

- Windows 10/11
- Visual Studio 2022 or later
- Swift for Windows (Swift 5.9+)
- CMake 3.20+

### Building

1. **Open Developer Command Prompt**:
   ```cmd
   "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
   ```

2. **Build the project**:
   ```cmd
   cd windows
   cmake -B build -S .
   cmake --build build --config Release
   ```

3. **Run the application**:
   ```cmd
   build\Release\ThreeBlindMice.exe
   ```

## 🔧 Technical Details

### Architecture

- **Swift Core**: Main triangulation logic in Swift
- **C++ Bridge**: Windows Raw Input API wrapper
- **Win32 Integration**: Native Windows mouse control
- **CMake Build**: Cross-platform build system

### Windows-Specific Features

- **Raw Input API**: Direct access to multiple mice
- **Windows Cursor Control**: Native cursor positioning
- **Permission Handling**: Windows UAC and security model
- **System Tray**: Windows notification area integration

## 📁 File Structure

```
windows/
├── src/
│   ├── swift/              # Swift source code
│   │   ├── main.swift     # Main application entry
│   │   └── MultiMouseManager.swift
│   └── cpp/               # C++ Windows API wrapper
│       ├── hid_manager.cpp
│       ├── hid_manager.h
│       └── mouse_control.cpp
├── CMakeLists.txt         # CMake build configuration
├── ThreeBlindMice.sln     # Visual Studio solution
├── build.bat              # Windows build script
├── run.bat                # Windows run script
└── README.md              # This file
```

## 🎮 Usage

### GUI Version

1. **Launch**: Run `ThreeBlindMice.exe`
2. **System Tray**: Look for the 🐭 icon in the system tray
3. **Control**: Right-click the tray icon for options
4. **Start**: Click "Start Triangulation" to begin

### CLI Version

1. **Run**: Execute `ThreeBlindMice.exe` from command prompt
2. **Connect Mice**: Plug in multiple mice
3. **Use**: Move any mouse to control the cursor
4. **Exit**: Press Ctrl+C to stop

## 🔒 Permissions

Windows may require administrator privileges for HID access:

1. **Run as Administrator**: Right-click and select "Run as administrator"
2. **UAC Prompt**: Allow the application to make system changes
3. **Antivirus**: Add exception if blocked by antivirus software

## 🛠️ Development

### Building from Source

1. **Clone and navigate**:
   ```cmd
   git clone <repository-url>
   cd 3BlindMice\windows
   ```

2. **Generate project files**:
   ```cmd
   cmake -B build -S .
   ```

3. **Build**:
   ```cmd
   cmake --build build --config Release
   ```

### Visual Studio Integration

1. **Open**: `ThreeBlindMice.sln` in Visual Studio
2. **Build**: Press F7 or Build → Build Solution
3. **Run**: Press F5 or Debug → Start Debugging

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**: Run as administrator
2. **Missing DLLs**: Install Visual C++ Redistributable
3. **HID Access Failed**: Check Windows privacy settings
4. **Build Errors**: Ensure Visual Studio tools are installed

### Debug Mode

Run in debug mode for detailed logging:
```cmd
build\Debug\ThreeBlindMice.exe
```

## 📄 License

This project is licensed under the MIT License - see the main `LICENSE` file for details.

---

**3 Blind Mice Windows** - Multi-mouse control for Windows! 🐭🪟
