# 3 Blind Mice - Cross-Platform Icon Generator

A comprehensive icon generation system that creates platform-specific icons for macOS, Windows, Linux, and ChromeOS from a single source image or programmatically generated mouse icons.

## 🎯 Features

- **Cross-Platform Support**: Generates icons for all supported platforms
- **Multiple Formats**: PNG, ICO, ICNS, SVG support
- **Programmatic Generation**: Creates mouse-themed icons without source images
- **Platform-Specific Optimization**: Tailored icon sizes and formats for each platform
- **Multiple Implementations**: Python, Shell Script, and Node.js versions
- **Automated Manifests**: Creates platform-specific configuration files

## 📁 Available Generators

### 1. Python Generator (`generate_icons.py`)
**Most Feature-Rich**

```bash
# Install dependencies
pip install Pillow

# Generate from default icon.png
python3 scripts/generate_icons.py

# Generate from custom source image
python3 scripts/generate_icons.py logo.png

# Custom output directory
python3 scripts/generate_icons.py logo.png custom/icons/

# Specific platform
python3 scripts/generate_icons.py --platform macos logo.png
```

**Features:**
- ✅ High-quality image processing with Pillow
- ✅ Multiple icon styles (default, minimal, colorful)
- ✅ Platform-specific format conversion (ICO, ICNS, SVG)
- ✅ Comprehensive error handling
- ✅ Detailed progress reporting

### 2. Shell Script Generator (`generate_icons.sh`)
**Lightweight & Fast**

```bash
# Make executable
chmod +x scripts/generate_icons.sh

# Generate from default icon.png
./scripts/generate_icons.sh

# Generate from custom source image
./scripts/generate_icons.sh logo.png

# Custom output directory
./scripts/generate_icons.sh logo.png custom/icons/
```

**Features:**
- ✅ Uses ImageMagick or macOS sips
- ✅ Fast execution
- ✅ No additional dependencies (uses system tools)
- ✅ Cross-platform shell compatibility
- ✅ Automatic platform detection

### 3. Node.js Generator (`generate_icons.js`)
**Web-Friendly**

```bash
# Install dependencies
npm install sharp canvas

# Generate from default icon.png
node scripts/generate_icons.js

# Generate from custom source image
node scripts/generate_icons.js logo.png

# Custom output directory
node scripts/generate_icons.js logo.png custom/icons/
```

**Features:**
- ✅ Sharp library for high-performance image processing
- ✅ Canvas fallback for basic operations
- ✅ SVG generation support
- ✅ Modern JavaScript/Node.js
- ✅ Package.json integration ready

## 🎨 Generated Icon Sizes

### macOS
- **App Icon**: 16, 32, 64, 128, 256, 512, 1024px
- **Menu Bar**: 16, 32px
- **Dock**: 32, 64, 128, 256, 512px
- **Formats**: PNG, ICNS

### Windows
- **App Icon**: 16, 24, 32, 48, 64, 96, 128, 256px
- **Taskbar**: 16, 24, 32px
- **Desktop**: 32, 48, 64, 96, 128, 256px
- **Formats**: PNG, ICO

### Linux
- **App Icon**: 16, 24, 32, 48, 64, 96, 128, 256, 512px
- **Desktop**: 32, 48, 64, 96, 128, 256px
- **Panel**: 16, 24, 32px
- **Formats**: PNG, SVG

### ChromeOS
- **Extension**: 16, 32, 48, 128px
- **App Icon**: 16, 24, 32, 48, 64, 96, 128, 256px
- **Formats**: PNG

## 🚀 Quick Start

### Option 1: Python (Recommended)
```bash
# Install Pillow
pip install Pillow

# Generate all icons
python3 scripts/generate_icons.py

# Generate from your logo
python3 scripts/generate_icons.py your_logo.png
```

### Option 2: Shell Script
```bash
# Install ImageMagick (if not on macOS)
brew install imagemagick  # macOS
sudo apt install imagemagick  # Ubuntu/Debian

# Generate all icons
./scripts/generate_icons.sh

# Generate from your logo
./scripts/generate_icons.sh your_logo.png
```

### Option 3: Node.js
```bash
# Install dependencies
npm install sharp canvas

# Generate all icons
node scripts/generate_icons.js

# Generate from your logo
node scripts/generate_icons.js your_logo.png
```

## 📋 Output Structure

```
assets/icons/
├── macos/
│   ├── icon_16x16.png
│   ├── icon_32x32.png
│   ├── icon_64x64.png
│   ├── icon_128x128.png
│   ├── icon_256x256.png
│   ├── icon_512x512.png
│   ├── icon_1024x1024.png
│   ├── icon_16x16@2x.png
│   ├── icon_32x32@2x.png
│   ├── icon_128x128@2x.png
│   ├── icon_256x256@2x.png
│   ├── icon_512x512@2x.png
│   └── ThreeBlindMice.iconset/
│       ├── icon_16x16.png
│       ├── icon_16x16@2x.png
│       ├── icon_32x32.png
│       ├── icon_32x32@2x.png
│       ├── icon_128x128.png
│       ├── icon_128x128@2x.png
│       ├── icon_256x256.png
│       ├── icon_256x256@2x.png
│       ├── icon_512x512.png
│       └── icon_512x512@2x.png
├── windows/
│   ├── icon_16x16.png
│   ├── icon_24x24.png
│   ├── icon_32x32.png
│   ├── icon_48x48.png
│   ├── icon_64x64.png
│   ├── icon_96x96.png
│   ├── icon_128x128.png
│   ├── icon_256x256.png
│   ├── icon_256x256.ico
│   └── app_icons.rc
├── linux/
│   ├── icon_16x16.png
│   ├── icon_24x24.png
│   ├── icon_32x32.png
│   ├── icon_48x48.png
│   ├── icon_64x64.png
│   ├── icon_96x96.png
│   ├── icon_128x128.png
│   ├── icon_256x256.png
│   ├── icon_512x512.png
│   └── threeblindmice.desktop
└── chromeos/
    ├── icon_16x16.png
    ├── icon_32x32.png
    ├── icon_48x48.png
    ├── icon_128x128.png
    └── icon_manifest.json
```

## 🔧 Platform-Specific Integration

### macOS Integration
1. **Copy icons to Xcode project**:
   ```bash
   cp assets/icons/macos/ThreeBlindMice.iconset/* macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/
   ```

2. **Update Xcode project**:
   - Open `macos/ThreeBlindMice.xcodeproj`
   - Select `ThreeBlindMice` target
   - Go to "App Icons and Launch Images"
   - Drag icons from the `.iconset` directory

### Windows Integration
1. **Include resource file**:
   ```bash
   cp assets/icons/windows/app_icons.rc windows/src/
   ```

2. **Update CMakeLists.txt**:
   ```cmake
   # Add resource file to Windows build
   if(WIN32)
       set(RESOURCE_FILES src/app_icons.rc)
   endif()
   ```

### Linux Integration
1. **Install desktop file**:
   ```bash
   sudo cp assets/icons/linux/threeblindmice.desktop /usr/share/applications/
   ```

2. **Copy icons to system directory**:
   ```bash
   sudo cp assets/icons/linux/icon_*.png /usr/share/pixmaps/
   ```

### ChromeOS Integration
1. **Update extension manifest**:
   ```bash
   cp assets/icons/chromeos/icon_manifest.json chromeos/extension/icons/
   ```

2. **Update manifest.json**:
   ```json
   {
     "icons": {
       "16": "icons/icon_16x16.png",
       "32": "icons/icon_32x32.png",
       "48": "icons/icon_48x48.png",
       "128": "icons/icon_128x128.png"
     }
   }
   ```

## 🎨 Customization

### Icon Styles (Python Generator)
```python
# Default style
python3 scripts/generate_icons.py --style default

# Minimal style
python3 scripts/generate_icons.py --style minimal

# Colorful style
python3 scripts/generate_icons.py --style colorful
```

### Source Image Requirements
- **Format**: PNG, JPG, GIF, BMP, TIFF
- **Size**: Any size (will be resized automatically)
- **Quality**: Higher resolution source = better quality icons
- **Recommended**: Square aspect ratio, transparent background preferred

### Custom Icon Sizes
Edit the `CONFIG.iconSizes` in the generator scripts to add or modify icon sizes for specific platforms.

## 🛠️ Development

### Adding New Platforms
1. Add platform to `CONFIG.platforms`
2. Define icon sizes in `CONFIG.iconSizes`
3. Add platform-specific file generation in `createPlatformSpecificFiles()`
4. Update documentation

### Adding New Formats
1. Add format to `CONFIG.iconFormats`
2. Implement conversion logic in the generator
3. Update platform-specific integration guides

## 📊 Performance Comparison

| Generator | Speed | Quality | Dependencies | Features |
|-----------|-------|---------|--------------|----------|
| **Python** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Pillow | ⭐⭐⭐⭐⭐ |
| **Shell** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ImageMagick/sips | ⭐⭐⭐ |
| **Node.js** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Sharp/Canvas | ⭐⭐⭐⭐ |

## 🐛 Troubleshooting

### Common Issues

1. **"Pillow not found"**:
   ```bash
   pip install Pillow
   ```

2. **"ImageMagick not found"**:
   ```bash
   brew install imagemagick  # macOS
   sudo apt install imagemagick  # Ubuntu/Debian
   ```

3. **"Sharp not found"**:
   ```bash
   npm install sharp canvas
   ```

4. **"Permission denied"**:
   ```bash
   chmod +x scripts/generate_icons.sh
   ```

5. **"Source image not found"**:
   - Check file path is correct
   - Ensure image file exists
   - Use absolute path if relative path fails

### Platform-Specific Issues

- **macOS**: Ensure Xcode command line tools are installed
- **Windows**: May need Visual Studio for ICO conversion
- **Linux**: Install development packages for image processing
- **ChromeOS**: Ensure Chrome Extension APIs are available

## 📝 License

This icon generator is part of the 3 Blind Mice project and follows the same BSD License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Test across all platforms
5. Submit a pull request

---

**Icon Generator** - Cross-platform icon generation for 3 Blind Mice! 🐭🎨✨
