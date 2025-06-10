# 🐭 3BlindMice – Multi-Mouse Triangulation Tool for macOS

This project lets you use **multiple USB optical mice** to triangulate and control the macOS cursor in real time by averaging input deltas.

---

## 🧰 Compiling 3BlindMice

This guide shows how to build the 3BlindMice multi-mouse triangulation tool for macOS using Swift.

### 🖥 Requirements

- macOS 12 or newer
- Xcode Command Line Tools (`xcode-select --install`)
- Accessibility permissions (for cursor control)

### 📁 Files

- `3BlindMice.swift` — The core mouse input handler.

### 🔧 Build Instructions

1. Open Terminal and navigate to your project folder.
2. Compile the project using Swift:

   ```bash
   swiftc 3BlindMice.swift
   ```

   This creates an executable file named `3BlindMice`.

3. Grant Accessibility Permissions

   To move the system mouse cursor, 3BlindMice needs access:

   - Go to **System Settings → Privacy & Security → Accessibility**
   - Click `+`, then add:
     - Terminal (if running from Terminal)
     - or the compiled `3BlindMice` binary

   Make sure the checkbox is checked ✅.

✅ You’re ready to run `3BlindMice`. See below for how to use it.

---

## 🖱️ Using 3BlindMice

3BlindMice allows you to use multiple USB optical mice on macOS to control the system cursor by averaging their input deltas in real-time.

### 🚀 Running

Open Terminal and run:

```bash
./3BlindMice
```

You’ll see:

```
Multi-mouse triangulation active.
```

This means the app is running and listening for input.

### 🧠 How It Works

- Each mouse contributes its movement (delta X/Y)
- The app averages input across all mice
- The fused cursor position is warped accordingly
- macOS Y-axis is inverted (up is negative)

### 📋 Notes

- Works with **any number of USB mice**
- All devices must be recognized as HID mice by macOS
- This app uses `IOHIDManager` and `CGWarpMouseCursorPosition`

### 🛑 Stopping

Use `Ctrl + C` to quit in the terminal.

### 🛠️ Troubleshooting

- **Cursor doesn’t move**:
  - Check Accessibility permissions (see compilation steps)
  - Ensure mice are connected and recognized
- **Cursor jumps erratically**:
  - Make sure all connected devices are optical mice, not trackpads or special devices

### 🧪 Future Ideas

- Weighted averaging (e.g. for tracking devices)
- GUI overlay for cursor visualization
- Triangulation logic using position instead of deltas
- SwiftUI-based calibration interface

---

Happy hacking with your new triple-mouse tracking tool! 🐭🐭🐭
