import Foundation

/// Display information structure for Linux
public struct LinuxDisplayInfo {
    public let id: String
    public let name: String
    public let x: Int32
    public let y: Int32
    public let width: Int32
    public let height: Int32
    public let isPrimary: Bool
    public let scaleFactor: Float
    
    public init(id: String, name: String, x: Int32, y: Int32, width: Int32, height: Int32, isPrimary: Bool, scaleFactor: Float = 1.0) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.isPrimary = isPrimary
        self.scaleFactor = scaleFactor
    }
}

/// Linux multi-display manager
public class LinuxDisplayManager {
    public static let shared = LinuxDisplayManager()
    
    private init() {
        display_manager_init()
    }
    
    deinit {
        display_manager_cleanup()
    }
    
    /// Get all available displays
    public func getAllDisplays() -> [LinuxDisplayInfo] {
        var displays: [LinuxDisplayInfo] = []
        let count = display_manager_get_display_count()
        
        for i in 0..<count {
            var info = DisplayInfo()
            display_manager_get_display_info(i, &info)
            
            let display = LinuxDisplayInfo(
                id: String(cString: info.id),
                name: String(cString: info.name),
                x: info.x,
                y: info.y,
                width: info.width,
                height: info.height,
                isPrimary: info.isPrimary,
                scaleFactor: info.scaleFactor
            )
            displays.append(display)
        }
        
        return displays
    }
    
    /// Get primary display
    public func getPrimaryDisplay() -> LinuxDisplayInfo? {
        var info = DisplayInfo()
        display_manager_get_primary_display_info(&info)
        
        return LinuxDisplayInfo(
            id: String(cString: info.id),
            name: String(cString: info.name),
            x: info.x,
            y: info.y,
            width: info.width,
            height: info.height,
            isPrimary: true,
            scaleFactor: info.scaleFactor
        )
    }
    
    /// Get display at coordinates
    public func getDisplayAt(x: Int32, y: Int32) -> LinuxDisplayInfo? {
        var info = DisplayInfo()
        if display_manager_get_display_at(x, y, &info) != 0 {
            return LinuxDisplayInfo(
                id: String(cString: info.id),
                name: String(cString: info.name),
                x: info.x,
                y: info.y,
                width: info.width,
                height: info.height,
                isPrimary: info.isPrimary,
                scaleFactor: info.scaleFactor
            )
        }
        return nil
    }
    
    /// Clamp coordinates to display bounds
    public func clampToDisplayBounds(x: Int32, y: Int32, display: LinuxDisplayInfo) -> (x: Int32, y: Int32) {
        var clampedX: Int32 = 0
        var clampedY: Int32 = 0
        
        var cInfo = DisplayInfo()
        strncpy(&cInfo.id.0, display.id, 255)
        strncpy(&cInfo.name.0, display.name, 255)
        cInfo.x = display.x
        cInfo.y = display.y
        cInfo.width = display.width
        cInfo.height = display.height
        cInfo.isPrimary = display.isPrimary
        cInfo.scaleFactor = display.scaleFactor
        
        display_manager_clamp_to_display_bounds(x, y, &cInfo, &clampedX, &clampedY)
        return (clampedX, clampedY)
    }
    
    /// Update displays (refresh display information)
    public func updateDisplays() {
        display_manager_update_displays()
    }
}

// C interface declarations
@_silgen_name("display_manager_init")
func display_manager_init() -> Void

@_silgen_name("display_manager_cleanup")
func display_manager_cleanup() -> Void

@_silgen_name("display_manager_update_displays")
func display_manager_update_displays() -> Void

@_silgen_name("display_manager_get_display_count")
func display_manager_get_display_count() -> Int32

@_silgen_name("display_manager_get_display_info")
func display_manager_get_display_info(_ index: Int32, _ info: UnsafeMutablePointer<DisplayInfo>) -> Void

@_silgen_name("display_manager_get_primary_display_info")
func display_manager_get_primary_display_info(_ info: UnsafeMutablePointer<DisplayInfo>) -> Void

@_silgen_name("display_manager_get_display_at")
func display_manager_get_display_at(_ x: Int32, _ y: Int32, _ info: UnsafeMutablePointer<DisplayInfo>) -> Int32

@_silgen_name("display_manager_clamp_to_display_bounds")
func display_manager_clamp_to_display_bounds(_ x: Int32, _ y: Int32, _ display: UnsafePointer<DisplayInfo>, _ clampedX: UnsafeMutablePointer<Int32>, _ clampedY: UnsafeMutablePointer<Int32>) -> Void

// C struct for display info (matches the C header)
struct DisplayInfo {
    var id: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var name: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var x: Int32 = 0
    var y: Int32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var isPrimary: Bool = false
    var scaleFactor: Float = 1.0
}
