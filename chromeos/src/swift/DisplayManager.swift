import Foundation

/// Display information structure for ChromeOS
public struct ChromeOSDisplayInfo {
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

/// ChromeOS multi-display manager
public class ChromeOSDisplayManager {
    public static let shared = ChromeOSDisplayManager()
    
    private init() {
        chromeos_display_manager_init()
    }
    
    deinit {
        chromeos_display_manager_cleanup()
    }
    
    /// Get all available displays
    public func getAllDisplays() -> [ChromeOSDisplayInfo] {
        var displays: [ChromeOSDisplayInfo] = []
        let count = chromeos_display_manager_get_display_count()
        
        for i in 0..<count {
            var info = ChromeOSDisplayInfo_C()
            chromeos_display_manager_get_display_info(i, &info)
            
            let display = ChromeOSDisplayInfo(
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
    public func getPrimaryDisplay() -> ChromeOSDisplayInfo? {
        var info = ChromeOSDisplayInfo_C()
        chromeos_display_manager_get_primary_display_info(&info)
        
        return ChromeOSDisplayInfo(
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
    public func getDisplayAt(x: Int32, y: Int32) -> ChromeOSDisplayInfo? {
        var info = ChromeOSDisplayInfo_C()
        if chromeos_display_manager_get_display_at(x, y, &info) != 0 {
            return ChromeOSDisplayInfo(
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
    public func clampToDisplayBounds(x: Int32, y: Int32, display: ChromeOSDisplayInfo) -> (x: Int32, y: Int32) {
        var clampedX: Int32 = 0
        var clampedY: Int32 = 0
        
        var cInfo = ChromeOSDisplayInfo_C()
        strncpy(&cInfo.id.0, display.id, 255)
        strncpy(&cInfo.name.0, display.name, 255)
        cInfo.x = display.x
        cInfo.y = display.y
        cInfo.width = display.width
        cInfo.height = display.height
        cInfo.isPrimary = display.isPrimary
        cInfo.scaleFactor = display.scaleFactor
        
        chromeos_display_manager_clamp_to_display_bounds(x, y, &cInfo, &clampedX, &clampedY)
        return (clampedX, clampedY)
    }
    
    /// Update displays (refresh display information)
    public func updateDisplays() {
        chromeos_display_manager_update_displays()
    }
    
    /// Check if Crostini is available
    public func isCrostiniAvailable() -> Bool {
        return chromeos_display_manager_is_crostini_available()
    }
}

// C interface declarations
@_silgen_name("chromeos_display_manager_init")
func chromeos_display_manager_init() -> Void

@_silgen_name("chromeos_display_manager_cleanup")
func chromeos_display_manager_cleanup() -> Void

@_silgen_name("chromeos_display_manager_update_displays")
func chromeos_display_manager_update_displays() -> Void

@_silgen_name("chromeos_display_manager_get_display_count")
func chromeos_display_manager_get_display_count() -> Int32

@_silgen_name("chromeos_display_manager_get_display_info")
func chromeos_display_manager_get_display_info(_ index: Int32, _ info: UnsafeMutablePointer<ChromeOSDisplayInfo_C>) -> Void

@_silgen_name("chromeos_display_manager_get_primary_display_info")
func chromeos_display_manager_get_primary_display_info(_ info: UnsafeMutablePointer<ChromeOSDisplayInfo_C>) -> Void

@_silgen_name("chromeos_display_manager_get_display_at")
func chromeos_display_manager_get_display_at(_ x: Int32, _ y: Int32, _ info: UnsafeMutablePointer<ChromeOSDisplayInfo_C>) -> Int32

@_silgen_name("chromeos_display_manager_clamp_to_display_bounds")
func chromeos_display_manager_clamp_to_display_bounds(_ x: Int32, _ y: Int32, _ display: UnsafePointer<ChromeOSDisplayInfo_C>, _ clampedX: UnsafeMutablePointer<Int32>, _ clampedY: UnsafeMutablePointer<Int32>) -> Void

@_silgen_name("chromeos_display_manager_is_crostini_available")
func chromeos_display_manager_is_crostini_available() -> Bool

// C struct for ChromeOS display info (matches the C header)
struct ChromeOSDisplayInfo_C {
    var id: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var name: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var x: Int32 = 0
    var y: Int32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var isPrimary: Bool = false
    var scaleFactor: Float = 1.0
}
