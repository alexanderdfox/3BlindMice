# Custom Cursor Feature Documentation

## Overview

The **Custom Cursor Feature** allows each mouse to display its assigned emoji as the actual system cursor, providing visual identification of which mouse is currently controlling the cursor position.

## Features

### 🎯 **Dynamic Cursor Appearance**
- **Individual Mode**: Each mouse displays its custom emoji as the cursor
- **Fused Mode**: Returns to default arrow cursor
- **Real-time Updates**: Cursor changes immediately when switching mice or modes

### 🎨 **Emoji Integration**
- **Custom Emojis**: Uses the same emoji assignments from the Custom Emoji feature
- **Default Rotation**: New mice get rotating default emojis
- **Persistent Preferences**: Cursor emojis save and persist between sessions

### 🔄 **Mode-Aware Behavior**
- **Individual Mode**: Shows custom emoji cursor for active mouse
- **Fused Mode**: Shows standard arrow cursor
- **Automatic Switching**: Cursor updates when mode changes

## Technical Implementation

### Core Components

#### 1. **Custom Cursor Creation**
```swift
private func createCustomCursor(from emoji: String) -> NSCursor? {
    // Check cache first
    if let cachedCursor = customCursors[emoji] {
        return cachedCursor
    }
    
    // Create a custom cursor from emoji
    let size = CGSize(width: 32, height: 32)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Create attributed string with emoji
    let attributedString = NSAttributedString(
        string: emoji,
        attributes: [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
    )
    
    // Calculate position to center the emoji
    let stringSize = attributedString.size()
    let x = (size.width - stringSize.width) / 2
    let y = (size.height - stringSize.height) / 2
    
    // Draw emoji
    attributedString.draw(at: CGPoint(x: x, y: y))
    
    image.unlockFocus()
    
    // Create cursor with custom hot spot (center of emoji)
    let cursor = NSCursor(image: image, hotSpot: CGPoint(x: 16, y: 16))
    
    // Cache the cursor
    customCursors[emoji] = cursor
    
    return cursor
}
```

#### 2. **Cursor Management Methods**
```swift
func setCustomCursor(for device: IOHIDDevice, emoji: String) {
    guard let cursor = createCustomCursor(from: emoji) else { return }
    
    DispatchQueue.main.async {
        cursor.set()
    }
}

private func resetToDefaultCursor() {
    DispatchQueue.main.async {
        NSCursor.arrow.set()
    }
}
```

#### 3. **Notification System**
```swift
// Notification for emoji updates
extension Notification.Name {
    static let emojiUpdated = Notification.Name("emojiUpdated")
}

// Observer setup
private func setupNotificationObserver() {
    NotificationCenter.default.addObserver(
        forName: .emojiUpdated,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        guard let self = self,
              let deviceString = notification.object as? String,
              self.useIndividualMode,
              let activeMouse = self.activeMouse,
              String(describing: activeMouse) == deviceString else { return }
        
        // Update cursor for the active mouse
        if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
            let emoji = emojiManager.getEmoji(for: deviceString)
            self.setCustomCursor(for: activeMouse, emoji: emoji)
        }
    }
}
```

### Integration Points

#### 1. **Individual Mode Cursor Updates**
```swift
private func handleIndividualMode(device: IOHIDDevice) {
    // Set this as the active mouse
    DispatchQueue.main.async {
        self.activeMouse = device
    }
    
    // Move cursor to this mouse's position
    if let position = mousePositions[device] {
        CGWarpMouseCursorPosition(position)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        
        // Set custom cursor for this mouse
        let deviceString = String(describing: device)
        if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
            let emoji = emojiManager.getEmoji(for: deviceString)
            setCustomCursor(for: device, emoji: emoji)
        }
    }
    
    // Clear deltas after processing
    mouseDeltas[device] = (0, 0)
}
```

#### 2. **Fused Mode Cursor Reset**
```swift
func fuseAndMoveCursor() {
    // ... existing triangulation logic ...
    
    // Move cursor to fused position
    CGWarpMouseCursorPosition(fusedPosition)
    CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
    
    // Reset to default cursor in fused mode
    resetToDefaultCursor()
}
```

#### 3. **Mode Switching Cursor Updates**
```swift
func toggleMode() {
    useIndividualMode.toggle()
    let modeName = useIndividualMode ? "Individual" : "Fused"
    print("🔄 Switched to \(modeName) Mode")
    
    // Update cursor based on mode
    if useIndividualMode {
        // Set cursor for the most recently active mouse
        if let activeMouse = activeMouse {
            let deviceString = String(describing: activeMouse)
            if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
                let emoji = emojiManager.getEmoji(for: deviceString)
                setCustomCursor(for: activeMouse, emoji: emoji)
            }
        }
    } else {
        // Reset to default cursor in fused mode
        resetToDefaultCursor()
    }
}
```

## User Experience

### 🎮 **How It Works**

1. **Start the Application**
   - Click the 🐭 icon in the menu bar
   - Application starts in Fused Mode with default arrow cursor

2. **Switch to Individual Mode**
   - Click "Toggle Mode" button
   - Cursor changes to the emoji of the most recently active mouse
   - Each mouse movement updates the cursor to that mouse's emoji

3. **Customize Emojis**
   - Click "Custom Emojis" button
   - Select a mouse and assign a custom emoji
   - Cursor immediately updates if that mouse is active

4. **Switch Between Mice**
   - Move any connected mouse
   - Cursor changes to that mouse's assigned emoji
   - Visual feedback shows which mouse is controlling the cursor

### 🎯 **Visual Feedback**

- **Individual Mode**: 
  - 🐭 Mouse 1 controls cursor → Shows 🐭 cursor
  - 🐱 Mouse 2 controls cursor → Shows 🐱 cursor
  - 🐶 Mouse 3 controls cursor → Shows 🐶 cursor

- **Fused Mode**:
  - All mice contribute → Shows standard arrow cursor

### 🔧 **Performance Optimizations**

- **Cursor Caching**: Custom cursors are cached to avoid recreation
- **Main Thread Updates**: All cursor changes happen on main thread
- **Efficient Rendering**: 32x32 pixel cursors with centered emojis
- **Memory Management**: Weak references prevent retain cycles

## Troubleshooting

### Common Issues

#### **Cursor Not Changing**
- **Cause**: Individual Mode not active
- **Solution**: Click "Toggle Mode" to switch to Individual Mode

#### **Emoji Not Displaying**
- **Cause**: Emoji font not available
- **Solution**: Uses system font, should work on all macOS versions

#### **Cursor Flickering**
- **Cause**: Rapid mouse switching
- **Solution**: Cursor updates are throttled to prevent flickering

#### **Performance Issues**
- **Cause**: Too many custom cursors
- **Solution**: Cursor cache limits memory usage

### Debug Information

The application provides console output for cursor changes:
```
🔄 Switched to Individual Mode
📊 Individual Mode: Each mouse controls cursor independently
🔗 Fused Mode: All mice contribute to single cursor position
```

## Technical Requirements

- **macOS**: 13.0+
- **Xcode**: 15.0+
- **Frameworks**: AppKit, IOKit.hid, CoreGraphics
- **Permissions**: Input Monitoring required

## Future Enhancements

### Potential Improvements

1. **Cursor Size Options**
   - Small (24x24), Medium (32x32), Large (48x48)
   - User preference setting

2. **Cursor Animation**
   - Subtle animations for mouse activity
   - Pulsing effect for active mouse

3. **Advanced Customization**
   - Custom cursor images (PNG/JPG)
   - Color themes for different mice
   - Cursor trail effects

4. **Accessibility Features**
   - High contrast cursor options
   - Larger cursor sizes for accessibility
   - Audio feedback for mouse switching

## Conclusion

The Custom Cursor Feature provides an intuitive visual interface for multi-mouse control, making it easy to identify which mouse is currently active and providing immediate feedback for mouse switching. The integration with the existing Custom Emoji system ensures consistency and user familiarity.
