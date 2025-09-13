import Foundation
import AppKit

/// Display information structure
public struct DisplayInfo {
    public let id: String
    public let name: String
    public let frame: CGRect
    public let isPrimary: Bool
    public let scaleFactor: CGFloat
    
    public init(id: String, name: String, frame: CGRect, isPrimary: Bool, scaleFactor: CGFloat = 1.0) {
        self.id = id
        self.name = name
        self.frame = frame
        self.isPrimary = isPrimary
        self.scaleFactor = scaleFactor
    }
}

/// Multi-display manager for macOS
public class DisplayManager {
    public static let shared = DisplayManager()
    
    private var displays: [DisplayInfo] = []
    private var primaryDisplay: DisplayInfo?
    
    private init() {
        updateDisplays()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displaysChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Get all available displays
    public func getAllDisplays() -> [DisplayInfo] {
        return displays
    }
    
    /// Get primary display
    public func getPrimaryDisplay() -> DisplayInfo? {
        return primaryDisplay
    }
    
    /// Get display at specific coordinates
    public func getDisplayAt(x: CGFloat, y: CGFloat) -> DisplayInfo? {
        let point = CGPoint(x: x, y: y)
        
        // Find the display that contains this point
        for display in displays {
            if display.frame.contains(point) {
                return display
            }
        }
        
        // If not found, return primary display
        return primaryDisplay
    }
    
    /// Get display by ID
    public func getDisplayById(_ id: String) -> DisplayInfo? {
        return displays.first { $0.id == id }
    }
    
    /// Get total screen bounds (union of all displays)
    public func getTotalScreenBounds() -> CGRect {
        guard !displays.isEmpty else {
            return CGRect(x: 0, y: 0, width: 1920, height: 1080) // Default fallback
        }
        
        var unionRect = displays[0].frame
        for display in displays.dropFirst() {
            unionRect = unionRect.union(display.frame)
        }
        
        return unionRect
    }
    
    /// Convert global coordinates to display-relative coordinates
    public func convertToDisplayCoordinates(globalX: CGFloat, globalY: CGFloat) -> (display: DisplayInfo?, localX: CGFloat, localY: CGFloat) {
        guard let display = getDisplayAt(x: globalX, y: globalY) else {
            return (nil, globalX, globalY)
        }
        
        let localX = globalX - display.frame.origin.x
        let localY = globalY - display.frame.origin.y
        
        return (display, localX, localY)
    }
    
    /// Clamp coordinates to display bounds
    public func clampToDisplayBounds(x: CGFloat, y: CGFloat, display: DisplayInfo) -> (x: CGFloat, y: CGFloat) {
        let clampedX = max(display.frame.origin.x, min(x, display.frame.origin.x + display.frame.width - 1))
        let clampedY = max(display.frame.origin.y, min(y, display.frame.origin.y + display.frame.height - 1))
        
        return (clampedX, clampedY)
    }
    
    /// Update display information
    @objc private func displaysChanged() {
        updateDisplays()
    }
    
    private func updateDisplays() {
        displays.removeAll()
        
        for screen in NSScreen.screens {
            let displayId = "\(screen.hash)"
            let displayName = screen.localizedName
            let frame = screen.frame
            let isPrimary = screen == NSScreen.main
            let scaleFactor = screen.backingScaleFactor
            
            let displayInfo = DisplayInfo(
                id: displayId,
                name: displayName,
                frame: frame,
                isPrimary: isPrimary,
                scaleFactor: scaleFactor
            )
            
            displays.append(displayInfo)
            
            if isPrimary {
                primaryDisplay = displayInfo
            }
        }
        
        // Sort displays by position (left to right, top to bottom)
        displays.sort { display1, display2 in
            if display1.frame.origin.x != display2.frame.origin.x {
                return display1.frame.origin.x < display2.frame.origin.x
            }
            return display1.frame.origin.y < display2.frame.origin.y
        }
        
        print("🖥️  Updated displays: \(displays.count) found")
        for (index, display) in displays.enumerated() {
            print("   Display \(index + 1): \(display.name) (\(Int(display.frame.width))x\(Int(display.frame.height))) \(display.isPrimary ? "[PRIMARY]" : "")")
        }
    }
}
