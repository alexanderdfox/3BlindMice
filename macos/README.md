# 3 Blind Mice - macOS Implementation

## Overview

This directory contains the macOS-specific implementation of 3 Blind Mice, a multi-mouse triangulation system with HIPAA compliance for healthcare environments.

## 📁 Directory Structure

```
macos/
├── src/                          # Source code
│   ├── cli/                      # Command-line interface
│   │   ├── 3blindmice.swift     # Main CLI version
│   │   └── 3blindmice_with_permissions.swift
│   ├── gui/                      # Graphical interface (Xcode project)
│   │   └── ThreeBlindMice/       # SwiftUI application
│   └── hipaa/                    # HIPAA compliance modules
│       ├── HIPAASecurity.swift
│       └── HIPAADataManager.swift
├── ThreeBlindMice/               # SwiftUI GUI application
├── ThreeBlindMice.xcodeproj/     # Xcode project
├── ThreeBlindMice.xcworkspace/   # Xcode workspace
├── Package.swift                 # Swift Package Manager
├── scripts/                      # Build and utility scripts
│   ├── build_and_run.sh
│   ├── build.sh
│   ├── fix_permissions.sh
│   ├── generate_icon.sh
│   ├── install_icons.sh
│   ├── run_release.sh
│   └── test_permissions.sh
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites
- macOS 10.15+ (Catalina or later)
- Xcode 12+ with Swift 5.3+
- Multiple USB mice connected

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/3BlindMice.git
   cd 3BlindMice/macos
   ```

2. **Build the application**:
   ```bash
   # Using Swift Package Manager
   swift build
   
   # Or using Xcode
   open ThreeBlindMice.xcworkspace
   ```

3. **Run the application**:
   ```bash
   # CLI version
   swift run
   
   # GUI version (from Xcode)
   # Press Cmd+R to run
   ```

## 🔧 Build Options

### Swift Package Manager
```bash
# Build
swift build

# Run
swift run

# Release build
swift build -c release
```

### Xcode
```bash
# Open workspace
open ThreeBlindMice.xcworkspace

# Build from command line
xcodebuild -workspace ThreeBlindMice.xcworkspace -scheme ThreeBlindMice build
```

### Scripts
```bash
# Build and run
./scripts/build_and_run.sh

# Fix permissions
./scripts/fix_permissions.sh

# Test permissions
./scripts/test_permissions.sh
```

## 🏥 HIPAA Compliance

The macOS implementation includes comprehensive HIPAA compliance features:

### Security Features
- **AES-256 Encryption**: All PHI data encrypted at rest and in transit
- **Audit Logging**: Comprehensive tamper-proof audit logs
- **Access Controls**: Role-based access controls with multi-factor authentication
- **Data Minimization**: Collect and process only necessary data
- **Secure Disposal**: Secure deletion of PHI when no longer needed

### Healthcare Use Cases
- **Medical Device Control**: Multi-mouse control for medical equipment
- **Patient Care**: Collaborative patient care with multiple healthcare providers
- **Medical Imaging**: Multi-user control of imaging systems
- **Surgical Procedures**: Multi-surgeon collaboration during procedures
- **Rehabilitation**: Multi-therapist assistance for patient rehabilitation

## 🎯 Features

### Core Functionality
- **Multi-Mouse Support**: Connect and use multiple mice simultaneously
- **Individual Mouse Coordinates**: Track each mouse's position separately
- **Dual Control Modes**: Switch between fused triangulation and individual mouse control
- **Enhanced Triangulation**: Weighted averaging, activity tracking, and smoothing
- **Real-time UI**: Live display of connected mice and cursor position

### macOS-Specific Features
- **IOKit Integration**: Native HID device access
- **Core Graphics**: High-performance cursor control
- **TCC Permissions**: User-friendly permission handling
- **System Tray Integration**: Clean menu bar interface
- **Custom Cursor Display**: Each mouse shows its assigned emoji

### HIPAA Features
- **Audit Logging**: All mouse input logged with timestamps
- **Data Classification**: Automatic classification of sensitive data
- **Encryption**: AES-256 encryption for PHI data
- **Access Controls**: Role-based access management
- **Compliance Reporting**: Built-in compliance reporting tools

## 🔒 Permissions

### Required Permissions
- **Input Monitoring**: Required for HID device access
- **Accessibility**: Required for cursor control
- **Full Disk Access**: Required for secure audit logging

### Permission Setup
1. **System Preferences** → **Security & Privacy** → **Privacy**
2. **Input Monitoring**: Add the application
3. **Accessibility**: Add the application
4. **Full Disk Access**: Add the application (for HIPAA compliance)

### Troubleshooting Permissions
```bash
# Check current permissions
./scripts/test_permissions.sh

# Fix permission issues
./scripts/fix_permissions.sh
```

## 🧪 Testing

### Run Tests
```bash
# Run comprehensive tests
./test_macos.sh

# Test permissions
./scripts/test_permissions.sh

# Test HIPAA compliance
swift test --filter HIPAA
```

### Test with Multiple Mice
1. Connect multiple USB mice
2. Run the application
3. Move each mouse individually
4. Verify triangulation works correctly
5. Check audit logs for HIPAA compliance

## 📊 Performance

### System Requirements
- **CPU**: Intel or Apple Silicon
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 100MB for application
- **Input**: Multiple USB mice (2+ recommended)

### Optimization
- **IOKit**: Efficient HID device polling
- **Core Graphics**: Hardware-accelerated cursor control
- **Memory Management**: Automatic cleanup of inactive mice
- **Battery**: Optimized for laptop use

## 🔧 Development

### Project Structure
- **Swift Package**: `Package.swift` for CLI version
- **Xcode Project**: `ThreeBlindMice.xcodeproj` for GUI version
- **Source Code**: `src/` directory with modular structure
- **Scripts**: `scripts/` directory with build utilities

### Adding Features
1. **Core Logic**: Add to `src/cli/` or `src/gui/`
2. **HIPAA Features**: Add to `src/hipaa/`
3. **Tests**: Add to test directories
4. **Documentation**: Update this README

### Debugging
```bash
# Debug build
swift build --configuration debug

# Run with debug output
swift run --verbose

# Xcode debugging
# Set breakpoints in Xcode and run
```

## 📋 Troubleshooting

### Common Issues

#### No Mice Detected
- Check USB connections
- Verify mice are recognized by System Information
- Run `./scripts/test_permissions.sh`

#### Permission Denied
- Run `./scripts/fix_permissions.sh`
- Check System Preferences → Security & Privacy
- Restart the application

#### Cursor Not Moving
- Verify Accessibility permissions
- Check Input Monitoring permissions
- Test with single mouse first

#### HIPAA Compliance Issues
- Check audit log permissions
- Verify encryption key generation
- Review access control settings

### Debug Commands
```bash
# Check system information
system_profiler SPUSBDataType

# Check running processes
ps aux | grep ThreeBlindMice

# Check permissions
./scripts/test_permissions.sh

# View audit logs
tail -f ~/Library/Logs/ThreeBlindMice/audit.log
```

## 📞 Support

### Documentation
- **Main README**: `../README.md`
- **HIPAA Compliance**: `../docs/hipaa/`
- **Usage Guide**: `../docs/USAGE.md`

### Issues
- **GitHub Issues**: Report bugs and feature requests
- **Email**: support@3blindmice.com
- **Documentation**: Check `../docs/` directory

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the BSD License - see the `../LICENSE` file for details.

**HIPAA Compliance**: This software is HIPAA compliant and includes comprehensive security features for healthcare environments. See `../docs/hipaa/` for compliance documentation.

---

**3 Blind Mice** - Cross-platform multi-mouse control for macOS, Windows, Linux, and ChromeOS! 🐭🍎🪟🐧🌐
