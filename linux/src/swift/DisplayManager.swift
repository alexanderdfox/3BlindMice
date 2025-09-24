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
    
    // Helper to convert C char buffer to Swift String by pointer
    private func stringFrom(_ cStringStart: UnsafePointer<CChar>) -> String {
        return String(validatingUTF8: cStringStart) ?? ""
    }
    
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
            var idBuf = [CChar](repeating: 0, count: 256)
            var nameBuf = [CChar](repeating: 0, count: 256)
            var x:Int32=0, y:Int32=0, w:Int32=0, h:Int32=0
            var isPrimary: Bool=false
            var scale: Float=1.0
            dm_get_display_info_c(i, &idBuf, 256, &nameBuf, 256, &x, &y, &w, &h, &isPrimary, &scale)
            let display = LinuxDisplayInfo(
                id: String(cString: idBuf),
                name: String(cString: nameBuf),
                x: x, y: y, width: w, height: h,
                isPrimary: isPrimary,
                scaleFactor: scale
            )
            displays.append(display)
        }
        
        return displays
    }
    
    /// Get primary display
    public func getPrimaryDisplay() -> LinuxDisplayInfo? {
        var idBuf = [CChar](repeating: 0, count: 256)
        var nameBuf = [CChar](repeating: 0, count: 256)
        var x:Int32=0, y:Int32=0, w:Int32=0, h:Int32=0
        var isPrimary: Bool=false
        var scale: Float=1.0
        dm_get_primary_info_c(&idBuf, 256, &nameBuf, 256, &x, &y, &w, &h, &isPrimary, &scale)
        
        return LinuxDisplayInfo(
            id: String(cString: idBuf),
            name: String(cString: nameBuf),
            x: x, y: y, width: w, height: h,
            isPrimary: true,
            scaleFactor: scale
        )
    }
    
    /// Get display at coordinates
    public func getDisplayAt(x: Int32, y: Int32) -> LinuxDisplayInfo? {
        var idBuf = [CChar](repeating: 0, count: 256)
        var nameBuf = [CChar](repeating: 0, count: 256)
        var ox:Int32=0, oy:Int32=0, ow:Int32=0, oh:Int32=0
        var isPrimary: Bool=false
        var scale: Float=1.0
        if dm_get_display_at_c(x, y, &idBuf, 256, &nameBuf, 256, &ox, &oy, &ow, &oh, &isPrimary, &scale) != 0 {
            return LinuxDisplayInfo(
                id: String(cString: idBuf),
                name: String(cString: nameBuf),
                x: ox, y: oy, width: ow, height: oh,
                isPrimary: isPrimary,
                scaleFactor: scale
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
    var id: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var name: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var x: Int32 = 0
    var y: Int32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var isPrimary: Bool = false
    var scaleFactor: Float = 1.0
}
