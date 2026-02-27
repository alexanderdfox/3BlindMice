import AppKit
import CoreGraphics

/// Creates and sets custom emoji cursors. Use this instead of hiding the cursor—
/// setting a custom cursor replaces the default arrow, so no hide calls are needed.
final class CustomEmojiCursor {
    
    private var cursorCache: [String: NSCursor] = [:]
    
    /// Default emojis for each "mouse" cursor style
    static let defaultEmojis = ["🐭", "🐱", "🐶", "👆", "🎯", "⭐", "🔥", "✨"]
    
    /// Create an NSCursor from an emoji string
    func createCursor(from emoji: String, size: CGFloat = 32, fontSize: CGFloat = 24) -> NSCursor? {
        if let cached = cursorCache[emoji] { return cached }
        
        let imageSize = CGSize(width: size, height: size)
        let image = NSImage(size: imageSize)
        
        image.lockFocus()
        
        let attributedString = NSAttributedString(
            string: emoji,
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize),
                .foregroundColor: NSColor.labelColor
            ]
        )
        
        let stringSize = attributedString.size()
        let x = (imageSize.width - stringSize.width) / 2
        let y = (imageSize.height - stringSize.height) / 2
        
        attributedString.draw(at: CGPoint(x: x, y: y))
        image.unlockFocus()
        
        let hotSpot = CGPoint(x: size / 2, y: size / 2)
        let cursor = NSCursor(image: image, hotSpot: hotSpot)
        cursorCache[emoji] = cursor
        
        return cursor
    }
    
    /// Set the current cursor to a custom emoji
    func setCursor(emoji: String) {
        guard let cursor = createCursor(from: emoji) else { return }
        DispatchQueue.main.async { cursor.set() }
    }
    
    /// Reset to the default system arrow cursor
    func resetToDefault() {
        DispatchQueue.main.async { NSCursor.arrow.set() }
    }
}

// MARK: - Usage example (for scripting / REPL)

/*
 let cursorManager = CustomEmojiCursor()

 // Set custom emoji cursor (replaces default—no hide needed)
 cursorManager.setCursor(emoji: "🐭")

 // Cycle through emojis
 for emoji in CustomEmojiCursor.defaultEmojis {
     cursorManager.setCursor(emoji: emoji)
     Thread.sleep(forTimeInterval: 1.0)
 }

 // Restore default
 cursorManager.resetToDefault()
 */
