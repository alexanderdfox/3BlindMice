# HID Permissions Guide for 3 Blind Mice

## 🔒 Understanding TCC Permissions

The error `TCC deny IOHIDDeviceOpen` indicates that macOS is blocking access to HID (Human Interface Device) devices due to security restrictions. This is a feature of macOS's Transparency, Consent, and Control (TCC) framework.

## 🛠️ Solutions

### Solution 1: Grant Permissions via System Preferences

1. **Open System Preferences**
   - Go to Apple Menu → System Preferences (or System Settings on newer macOS)

2. **Navigate to Security & Privacy**
   - Click on "Security & Privacy" (or "Privacy & Security" on newer macOS)

3. **Select Input Monitoring**
   - Click on the "Privacy" tab
   - Look for "Input Monitoring" in the left sidebar
   - If not visible, click the lock icon and enter your password

4. **Add Your Application**
   - Click the "+" button
   - Navigate to your application:
     - **Xcode Version**: `/Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-*/Build/Products/Debug/ThreeBlindMice.app`
     - **Command Line Version**: Add Terminal.app or your terminal application
   - Check the box next to your application

5. **Restart Your Application**
   - Quit and relaunch the 3 Blind Mice application

### Solution 2: Grant Permissions via Terminal (Command Line Version)

For the command-line version, you need to grant permissions to Terminal.app:

```bash
# Check if Terminal has Input Monitoring permission
tccutil reset InputMonitoring com.apple.Terminal

# Or for iTerm2 (if using iTerm2)
tccutil reset InputMonitoring com.googlecode.iterm2
```

### Solution 3: Use Accessibility Permissions

Some systems may require Accessibility permissions instead:

1. **Open System Preferences → Security & Privacy → Privacy**
2. **Select "Accessibility"**
3. **Add your application or Terminal.app**
4. **Check the box to enable**

### Solution 4: Build with Proper Code Signing

The application needs to be properly code signed for permissions to work correctly:

```bash
# Build with proper code signing
xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release build

# Or for development
xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Debug build
```

## 🔧 Troubleshooting Steps

### Step 1: Check Current Permissions

```bash
# Check what applications have Input Monitoring permission
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client, auth_value FROM access WHERE service='kTCCServiceInputMonitoring';"
```

### Step 2: Reset Permissions (if needed)

```bash
# Reset Input Monitoring permissions
sudo tccutil reset InputMonitoring

# Reset Accessibility permissions
sudo tccutil reset Accessibility
```

### Step 3: Verify Application Path

Make sure you're granting permissions to the correct application:

```bash
# Find the exact path of your built application
find ~/Library/Developer/Xcode/DerivedData -name "ThreeBlindMice.app" -type d
```

### Step 4: Check Console Logs

Monitor system logs for permission issues:

```bash
# Watch for TCC-related messages
log stream --predicate 'subsystem == "com.apple.TCC"'
```

## 🚀 Alternative Solutions

### Option 1: Run as Root (Not Recommended for Production)

```bash
# Run with sudo (temporary solution)
sudo swift 3blindmice.swift
```

### Option 2: Create a Launch Agent

Create a launch agent that runs with proper permissions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.threeblindmice.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/swift</string>
        <string>/Users/alexanderfox/Projects/3BlindMice/3blindmice.swift</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

### Option 3: Use Xcode for Development

The Xcode version typically has better permission handling:

1. **Open the project in Xcode**
2. **Build and run from Xcode**
3. **Grant permissions when prompted**

## 📋 Permission Checklist

- [ ] **Input Monitoring**: Application has permission to monitor input devices
- [ ] **Accessibility** (if needed): Application has accessibility permissions
- [ ] **Code Signing**: Application is properly code signed
- [ ] **Entitlements**: Proper entitlements are configured
- [ ] **User Consent**: User has explicitly granted permissions

## 🔍 Debugging Commands

### Check Application Status

```bash
# Check if application is running
ps aux | grep ThreeBlindMice

# Check application permissions
codesign -dv /path/to/ThreeBlindMice.app
```

### Monitor System Logs

```bash
# Watch for HID-related messages
log stream --predicate 'process == "ThreeBlindMice"'

# Watch for TCC messages
log stream --predicate 'subsystem == "com.apple.TCC"'
```

## 🎯 Quick Fix for Development

For immediate testing, try this sequence:

1. **Build the Xcode project**
2. **Open System Preferences → Security & Privacy → Privacy → Input Monitoring**
3. **Add the built application**
4. **Run the application from Finder (not Xcode)**
5. **Grant permissions when prompted**

## ⚠️ Important Notes

- **Permissions are per-application**: Each build may need separate permission
- **Debug vs Release**: Debug builds may have different permission requirements
- **Code signing matters**: Properly signed apps have better permission handling
- **User consent required**: Users must explicitly grant permissions
- **System restart**: Sometimes a restart is needed after permission changes

## 🆘 If Nothing Works

If you're still having issues:

1. **Check macOS version**: Some versions have stricter TCC policies
2. **Try different terminal**: Use Terminal.app instead of iTerm2 or vice versa
3. **Check SIP status**: System Integrity Protection may affect permissions
4. **Contact Apple Developer Support**: For persistent issues

---

*This guide should resolve the TCC permission issues and allow the 3 Blind Mice application to access HID devices properly.*
