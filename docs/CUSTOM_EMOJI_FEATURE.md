# Custom Emoji Feature

## 🎨 Overview

The **Custom Emoji Feature** allows users to assign personalized emojis to each connected mouse, making it easier to identify and distinguish between different mice in the interface.

## ✨ Features

### **Default Emoji Assignment**
- Each mouse automatically gets assigned a default emoji from a curated collection
- Default emojis include: 🐭, 🐹, 🐰, 🐱, 🐶, 🐸, 🐵, 🐼, 🐨, 🐯, 🦁, 🐮, 🐷, 🐸, 🐙, 🦄, 🦋, 🐞, 🦕, 🦖
- Emojis are assigned in rotation to ensure each mouse has a unique identifier

### **Custom Emoji Selection**
- **Quick Picker**: Choose from 20 pre-selected emojis
- **Custom Input**: Enter any emoji of your choice
- **Reset Function**: Return to default emoji assignment
- **Persistent Storage**: Emoji preferences are saved between app sessions

### **Visual Integration**
- Custom emojis appear in all mouse position displays
- Active mouse highlighting with custom emoji
- Detailed mouse information with personalized emojis
- Consistent emoji usage across all UI elements

## 🎯 How to Use

### **Accessing the Feature**
1. Click the 🐭 icon in your menu bar
2. Click the **"Custom Emojis"** button (pink button with smiley face icon)
3. The emoji settings panel will appear

### **Setting Custom Emojis**

#### **Method 1: Quick Picker**
1. In the emoji settings, you'll see a grid of 20 default emojis
2. Click on any emoji to assign it to the selected mouse
3. The emoji will be immediately applied

#### **Method 2: Custom Input**
1. In the "Custom" section, enter any emoji in the text field
2. Click "Set" to apply the custom emoji
3. The emoji will be saved and displayed

### **Managing Emojis**
- **View Current Assignments**: See all custom emoji assignments in the settings
- **Reset to Default**: Click "Reset" next to any mouse to return to default emoji
- **Automatic Assignment**: New mice automatically get the next available default emoji

## 🔧 Technical Implementation

### **EmojiManager Class**
```swift
class EmojiManager: ObservableObject {
    @Published var mouseEmojis: [String: String] = [:]
    private let defaultEmojis = ["🐭", "🐹", "🐰", "🐱", "🐶", "🐸", "🐵", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐙", "🦄", "🦋", "🐞", "🦕", "🦖"]
    
    func getEmoji(for device: String) -> String
    func setEmoji(for device: String, emoji: String)
    func resetEmoji(for device: String)
    func getDefaultEmojis() -> [String]
}
```

### **Persistent Storage**
- Emoji preferences are stored in `UserDefaults` with key `"MouseEmojis"`
- Data is automatically saved and loaded between app sessions
- JSON encoding/decoding for reliable data persistence

### **UI Integration**
- **IndividualMousePositionsView**: Shows custom emojis in position list
- **DetailedMouseInfoView**: Displays custom emojis in detailed information
- **EmojiSettingsView**: Provides emoji management interface

## 🎨 UI Components

### **Emoji Settings Panel**
- **Current Assignments**: Shows all custom emoji assignments
- **Quick Picker Grid**: 5x4 grid of default emojis for easy selection
- **Custom Input Field**: Text field for entering any emoji
- **Reset Buttons**: Individual reset buttons for each mouse

### **Visual Feedback**
- **Active Mouse Highlighting**: Custom emoji changes color when mouse is active
- **Consistent Sizing**: All emojis displayed at `title2` font size
- **Color Coding**: Green for active mice, gray for inactive

## 🔄 Default Emoji Rotation

The system automatically assigns default emojis in a rotating pattern:

1. **First Mouse**: 🐭 (Mouse)
2. **Second Mouse**: 🐹 (Hamster)
3. **Third Mouse**: 🐰 (Rabbit)
4. **Fourth Mouse**: 🐱 (Cat)
5. **Fifth Mouse**: 🐶 (Dog)
...and so on through the 20 available default emojis

If more than 20 mice are connected, the rotation starts over from the beginning.

## 💾 Data Persistence

### **Storage Format**
```json
{
  "device_id_1": "🐭",
  "device_id_2": "🦄",
  "device_id_3": "🐸"
}
```

### **Automatic Saving**
- Emoji assignments are saved immediately when changed
- No manual save action required
- Data persists across app restarts and system reboots

## 🎯 Use Cases

### **Multi-User Scenarios**
- **Collaborative Design**: Each user gets their own emoji (🐭, 🐱, 🐶)
- **Gaming Sessions**: Players can choose their favorite animal emoji
- **Accessibility**: Visual distinction helps users with multiple mice

### **Professional Use**
- **Design Teams**: Assign emojis based on team member preferences
- **Testing Environments**: Use emojis to identify different test mice
- **Presentation**: Clear visual identification during demos

### **Personal Customization**
- **Fun Factor**: Make the interface more enjoyable and personal
- **Easy Identification**: Quickly spot which mouse is which
- **Branding**: Use emojis that match your personal style

## 🔧 Troubleshooting

### **Common Issues**

#### **Emoji Not Displaying**
- **Cause**: System font doesn't support the emoji
- **Solution**: Try a different emoji or use one from the default set

#### **Emoji Not Saving**
- **Cause**: UserDefaults storage issue
- **Solution**: Restart the application

#### **Default Emojis Not Rotating**
- **Cause**: All default emojis already assigned
- **Solution**: Reset some mice to free up default emojis

### **Best Practices**
- **Use Standard Emojis**: Stick to widely-supported emoji characters
- **Keep It Simple**: Choose easily recognizable emojis
- **Consistent Usage**: Use the same emoji for the same mouse consistently

## 🚀 Future Enhancements

### **Planned Features**
- **Emoji Categories**: Organize emojis by theme (animals, objects, etc.)
- **Custom Emoji Upload**: Support for custom image uploads
- **Emoji Animation**: Animated emojis for active mice
- **Emoji Sharing**: Share emoji configurations between users

### **Advanced Customization**
- **Emoji Size Control**: Adjust emoji display size
- **Color Themes**: Custom color schemes for emojis
- **Emoji Effects**: Special effects for different mouse states

---

**🎨 The Custom Emoji Feature makes multi-mouse management more personal and intuitive!** 🐭🐱🐶
