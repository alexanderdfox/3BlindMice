# Individual Mouse Coordinates Feature

## 🎯 Overview

The **3 Blind Mice** application now supports keeping coordinates of each mouse separate, allowing for individual mouse tracking and control modes. This feature provides two distinct operating modes:

1. **Fused Mode** (Default): Traditional triangulation where all mouse movements are combined
2. **Individual Mode**: Each mouse maintains its own coordinate system and controls the cursor independently

## 🔄 Mode Switching

### CLI Version
- **Press 'M'**: Toggle between Individual and Fused modes
- **Press 'I'**: Show individual mouse positions
- **Press 'A'**: Show active mouse
- **Press 'Ctrl+C'**: Exit

### GUI Version
- **Toggle Mode Button**: Click to switch between modes
- **Real-time Display**: Shows current mode and individual mouse positions
- **Active Mouse Highlighting**: Highlights the currently active mouse

## 📊 Individual Mouse Tracking

### What's Tracked
- **Individual Positions**: Each mouse maintains its own (x, y) coordinates
- **Screen Boundaries**: Positions are clamped to screen dimensions
- **Activity Timestamps**: Last activity time for each mouse
- **Weight Values**: Dynamic weight based on activity level

### Coordinate System
- **Origin**: Top-left corner (0, 0)
- **X-axis**: Left to right (increasing)
- **Y-axis**: Top to bottom (increasing)
- **Bounds**: Clamped to screen dimensions

## 🎮 Operating Modes

### Fused Mode (Default)
```
🐭 Mouse 1: (100, 200) → Weight: 1.2
🐭 Mouse 2: (300, 400) → Weight: 0.8
🐭 Mouse 3: (500, 600) → Weight: 1.0
     ↓
🎯 Cursor: Weighted average position
```

**Features:**
- Weighted averaging of all mouse movements
- Activity-based weight adjustment
- Smoothing for jitter reduction
- Screen boundary clamping

### Individual Mode
```
🐭 Mouse 1: (100, 200) → ACTIVE
🐭 Mouse 2: (300, 400) → Inactive
🐭 Mouse 3: (500, 600) → Inactive
     ↓
🎯 Cursor: Follows most recently moved mouse
```

**Features:**
- Each mouse maintains independent coordinates
- Cursor follows the most recently active mouse
- Automatic switching between mice based on activity
- Individual position tracking

## 🔧 Technical Implementation

### Data Structures
```swift
private var mousePositions: [IOHIDDevice: CGPoint] = [:]
private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
private var mouseWeights: [IOHIDDevice: Double] = [:]
private var mouseActivity: [IOHIDDevice: Date] = [:]
private var useIndividualMode: Bool = false
private var activeMouse: IOHIDDevice?
```

### Key Methods
- `updateIndividualMousePosition()`: Updates individual mouse coordinates
- `handleIndividualMode()`: Manages individual mouse control
- `toggleMode()`: Switches between modes
- `getIndividualMousePositions()`: Returns all mouse positions
- `getActiveMouse()`: Returns currently active mouse

## 🎯 Use Cases

### Individual Mode Benefits
1. **Precision Work**: Each user can work in their own area
2. **Collaborative Design**: Multiple designers can work simultaneously
3. **Gaming**: Multiple players can control different elements
4. **Accessibility**: Caregivers can assist without interference
5. **Education**: Multiple students can interact independently

### Fused Mode Benefits
1. **Unified Control**: All mice contribute to single cursor
2. **Weighted Input**: Active mice have more influence
3. **Smooth Movement**: Reduced jitter through averaging
4. **Collaborative Tasks**: Multiple users working on same element

## 📱 GUI Features

### Real-time Display
- **Mode Indicator**: Shows current mode (Individual/Fused)
- **Mouse List**: Displays all connected mice with positions
- **Active Highlighting**: Green highlight for active mouse
- **Position Updates**: Real-time coordinate updates

### Control Panel
- **Toggle Button**: Easy mode switching
- **Status Display**: Connected mice count and mode
- **Position Monitoring**: Live cursor position tracking

## 🔍 Debugging

### CLI Debugging
```bash
# Show individual positions
Press 'I' in CLI version

# Show active mouse
Press 'A' in CLI version

# Toggle mode
Press 'M' in CLI version
```

### GUI Debugging
- **Mouse Positions**: Visible in control panel
- **Mode Status**: Displayed in status section
- **Active Mouse**: Highlighted in mouse list

## 🚀 Performance Considerations

### Memory Usage
- **Individual Tracking**: ~24 bytes per mouse (CGPoint + metadata)
- **Activity Tracking**: ~8 bytes per mouse (Date + weight)
- **Total Overhead**: Minimal for typical use cases

### Processing Overhead
- **Position Updates**: O(1) per mouse movement
- **Mode Switching**: O(1) operation
- **UI Updates**: 10 FPS refresh rate

## 🔧 Configuration

### Default Settings
- **Starting Position**: (500, 500) for all mice
- **Mode**: Fused (traditional behavior)
- **Update Rate**: 60 FPS for smooth movement
- **Activity Timeout**: 2 seconds for weight adjustment

### Customization
- Modify `smoothingFactor` for movement sensitivity
- Adjust `activityTimeout` for weight decay rate
- Change default starting positions in initialization

## 📋 Troubleshooting

### Common Issues
1. **Mouse Not Detected**: Check HID permissions
2. **Position Jumping**: Verify screen bounds clamping
3. **Mode Not Switching**: Ensure application is active
4. **Performance Issues**: Reduce update frequency if needed

### Debug Commands
```bash
# Test CLI version
./scripts/build.sh

# Test GUI version
./scripts/build_and_run.sh

# Check permissions
./scripts/test_permissions.sh
```

---

**Individual Mouse Coordinates** - Making multi-mouse control more flexible and powerful! 🐭🐭🐭
