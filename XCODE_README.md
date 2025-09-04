# 3 Blind Mice - Xcode Project

This document explains how to use the Xcode project for the 3 Blind Mice multi-mouse triangulation application.

## 📁 Project Structure

```
3BlindMice/
├── ThreeBlindMice.xcodeproj/          # Xcode project file
├── ThreeBlindMice.xcworkspace/        # Xcode workspace file
├── ThreeBlindMice/                    # Source code directory
│   ├── ThreeBlindMiceApp.swift        # Main application file
│   ├── Info.plist                     # Application configuration
│   ├── ThreeBlindMice.entitlements    # App permissions
│   └── Assets.xcassets/               # App icons and assets
│       └── AppIcon.appiconset/        # App icon configurations
├── 3blindmice.swift                   # Original command-line version
├── USAGE.md                           # Comprehensive usage guide
├── README.md                          # Main project documentation
├── Package.swift                      # Swift package configuration
├── build.sh                           # Swift package build script
└── generate_icon.sh                   # Icon generation script
```

## 🚀 Getting Started

### Opening the Project

1. **Using Xcode**:
   ```bash
   open ThreeBlindMice.xcworkspace
   ```
   or
   ```bash
   open ThreeBlindMice.xcodeproj
   ```

2. **From Finder**: Double-click `ThreeBlindMice.xcworkspace`

### Building and Running

1. **In Xcode**:
   - Select the "ThreeBlindMice" target
   - Choose your desired scheme (Debug/Release)
   - Press ⌘+R to build and run

2. **From Terminal**:
   ```bash
   xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release
   ```

## ⚙️ Project Configuration

### Build Settings

- **Deployment Target**: macOS 13.0+
- **Swift Version**: 5.0
- **Bundle Identifier**: `com.threeblindmice.app`
- **Version**: 1.0
- **Build**: 1

### Key Features

- **LSUIElement**: App runs in menu bar (no dock icon)
- **App Sandbox**: Disabled for HID access
- **USB/HID Permissions**: Enabled for mouse detection
- **Code Signing**: Automatic

### Entitlements

The app requires the following entitlements:
- `com.apple.security.app-sandbox`: Disabled
- `com.apple.security.device.usb`: Enabled
- `com.apple.security.device.hid`: Enabled

## 🎨 App Icon

### Generating Icons

1. **Using the provided script**:
   ```bash
   ./generate_icon.sh
   ```
   This requires ImageMagick to be installed.

2. **Manual creation**:
   - Create icons with the 🐭 emoji
   - Required sizes: 16x16, 32x32, 128x128, 256x256, 512x512 (1x and 2x)
   - Place in `ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/`

### Icon Specifications

- **Format**: PNG
- **Color Space**: sRGB
- **Transparency**: Supported
- **Design**: Mouse emoji (🐭) centered on transparent background

## 🔧 Development Workflow

### Adding New Features

1. **Create new Swift files** in the `ThreeBlindMice/` directory
2. **Add to project**: Drag files into Xcode project navigator
3. **Update Info.plist**: Add any new permissions or settings
4. **Test**: Build and run to verify changes

### Debugging

1. **Console Output**: Check Xcode console for debug messages
2. **Breakpoints**: Set breakpoints in `ThreeBlindMiceApp.swift`
3. **Menu Bar**: Look for the 🐭 icon in your menu bar
4. **Permissions**: Verify accessibility permissions are granted

### Testing

1. **Connect Multiple Mice**: Plug in 2-3 USB mice
2. **Launch App**: Build and run from Xcode
3. **Test Triangulation**: Click the menu bar icon and start triangulation
4. **Verify Movement**: Move mice to see averaged cursor control

## 📦 Distribution

### Creating Release Build

1. **Archive the app**:
   - Product → Archive
   - Select "Distribute App"
   - Choose "Copy App"

2. **Code Signing**:
   - Ensure you have a valid developer certificate
   - Configure signing in project settings

3. **Notarization** (for distribution outside App Store):
   - Use `xcrun altool` or `xcrun notarytool`
   - Submit for notarization

### App Store Distribution

1. **Create App Store Connect record**
2. **Upload build** using Xcode Organizer
3. **Submit for review**

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**:
   - Check Swift version compatibility
   - Verify all files are added to project
   - Clean build folder (⌘+Shift+K)

2. **Runtime Errors**:
   - Check console for error messages
   - Verify HID permissions
   - Ensure mice are properly connected

3. **Menu Bar Icon Not Appearing**:
   - Check `LSUIElement` setting in Info.plist
   - Verify app is running (check Activity Monitor)
   - Restart the application

4. **Mouse Detection Issues**:
   - Verify USB connections
   - Check System Settings → Privacy & Security → Accessibility
   - Ensure mice are recognized by macOS

### Debugging Tips

1. **Add NSLog statements** for debugging
2. **Use Xcode's Debug Navigator** to monitor resources
3. **Check Console.app** for system-level messages
4. **Test with different mouse brands** for compatibility

## 🔄 Version Control

### Git Integration

The project is configured for Git:
- `.gitignore` includes Xcode-specific files
- Source files are tracked
- Build products are ignored

### Branching Strategy

- `main`: Stable releases
- `develop`: Active development
- Feature branches: For new features

## 📚 Additional Resources

- [Apple HID Programming Guide](https://developer.apple.com/documentation/iokit/human_interface_device_programming_guide)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS App Programming Guide](https://developer.apple.com/documentation/appkit)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

*This Xcode project provides a professional development environment for the 3 Blind Mice application. Use it for development, debugging, and distribution.*
