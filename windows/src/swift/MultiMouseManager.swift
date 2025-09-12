import Foundation

// Windows-specific mouse position structure
struct MousePosition {
    var x: Double
    var y: Double
    
    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
}

// Windows-specific mouse delta structure
struct MouseDelta {
    var x: Int32
    var y: Int32
    
    init(x: Int32 = 0, y: Int32 = 0) {
        self.x = x
        self.y = y
    }
}

class MultiMouseManager {
    private var mouseDeltas: [UInt32: MouseDelta] = [:]
    private var mousePositions: [UInt32: MousePosition] = [:]
    private var mouseWeights: [UInt32: Double] = [:]
    private var mouseActivity: [UInt32: Date] = [:]
    private var fusedPosition = MousePosition(x: 500, y: 500)
    private var lastUpdateTime = Date()
    private var smoothingFactor: Double = 0.7
    private var useIndividualMode = false
    private var activeMouse: UInt32? = nil
    
    // Windows-specific HID manager handle
    private var hidManagerHandle: UnsafeMutableRawPointer? = nil
    
    init() {
        print("🐭 Enhanced Multi-Mouse Triangulation System (Windows)")
        print("======================================================")
        print("Features: Weighted averaging, activity tracking, smoothing")
        print("")
        
        // Initialize Windows HID manager
        initializeWindowsHIDManager()
    }
    
    private func initializeWindowsHIDManager() {
        // Initialize Windows Raw Input API
        hidManagerHandle = createWindowsHIDManager()
        
        if hidManagerHandle == nil {
            print("❌ Failed to initialize Windows HID Manager")
            print("")
            print("🔒 Permission Issue Detected!")
            print("=============================")
            print("This is a Windows security feature. You may need administrator privileges.")
            print("")
            print("📋 How to fix:")
            print("1. Right-click Command Prompt and select 'Run as administrator'")
            print("2. Navigate to the application directory")
            print("3. Run the application again")
            print("")
            print("💡 Alternative: Check Windows privacy settings for input monitoring")
            print("")
            return
        }
        
        print("✅ Windows HID Manager initialized successfully")
        print("🎯 Ready to detect mouse movements")
        print("")
    }
    
    func handleInput(deviceId: UInt32, deltaX: Int32, deltaY: Int32) {
        let currentTime = Date()
        
        // Update mouse activity timestamp
        mouseActivity[deviceId] = currentTime
        
        // Initialize mouse weight and position if not set
        if mouseWeights[deviceId] == nil {
            mouseWeights[deviceId] = 1.0
        }
        if mousePositions[deviceId] == nil {
            mousePositions[deviceId] = MousePosition(x: 500, y: 500)
        }
        
        // Update mouse delta
        var delta = mouseDeltas[deviceId] ?? MouseDelta()
        delta.x += deltaX
        delta.y += deltaY
        mouseDeltas[deviceId] = delta
        
        // Update individual mouse position
        updateIndividualMousePosition(deviceId: deviceId, delta: delta)
        
        // Update mouse weights based on activity
        updateMouseWeights()
        
        // Handle cursor movement based on mode
        if useIndividualMode {
            handleIndividualMode(deviceId: deviceId)
        } else {
            fuseAndMoveCursor()
        }
    }
    
    private func updateIndividualMousePosition(deviceId: UInt32, delta: MouseDelta) {
        guard let currentPos = mousePositions[deviceId] else { return }
        
        let newX = currentPos.x + Double(delta.x)
        let newY = currentPos.y + Double(delta.y)
        
        // Get screen bounds (Windows-specific)
        let screenWidth = getScreenWidth()
        let screenHeight = getScreenHeight()
        
        mousePositions[deviceId] = MousePosition(
            x: max(0, min(newX, Double(screenWidth) - 1)),
            y: max(0, min(newY, Double(screenHeight) - 1))
        )
    }
    
    private func handleIndividualMode(deviceId: UInt32) {
        // Set this as the active mouse
        activeMouse = deviceId
        
        // Move cursor to this mouse's position
        if let position = mousePositions[deviceId] {
            setCursorPosition(x: Int32(position.x), y: Int32(position.y))
        }
        
        // Clear deltas after processing
        mouseDeltas[deviceId] = MouseDelta()
    }
    
    private func updateMouseWeights() {
        let currentTime = Date()
        let activityTimeout: TimeInterval = 2.0
        
        for (deviceId, lastActivity) in mouseActivity {
            let timeSinceActivity = currentTime.timeIntervalSince(lastActivity)
            
            // Reduce weight for inactive mice
            if timeSinceActivity > activityTimeout {
                mouseWeights[deviceId] = max(0.1, (mouseWeights[deviceId] ?? 1.0) * 0.9)
            } else {
                // Increase weight for active mice
                mouseWeights[deviceId] = min(2.0, (mouseWeights[deviceId] ?? 1.0) * 1.1)
            }
        }
    }
    
    func fuseAndMoveCursor() {
        let count = mouseDeltas.count
        guard count > 0 else { return }
        
        let currentTime = Date()
        
        // Calculate weighted average of mouse movements
        var weightedTotalX: Double = 0
        var weightedTotalY: Double = 0
        var totalWeight: Double = 0
        
        for (deviceId, delta) in mouseDeltas {
            let weight = mouseWeights[deviceId] ?? 1.0
            weightedTotalX += Double(delta.x) * weight
            weightedTotalY += Double(delta.y) * weight
            totalWeight += weight
        }
        
        guard totalWeight > 0 else { return }
        
        let avgX = weightedTotalX / totalWeight
        let avgY = weightedTotalY / totalWeight
        
        // Apply smoothing to position updates
        let timeDelta = currentTime.timeIntervalSince(lastUpdateTime)
        let smoothing = min(1.0, timeDelta * 60.0) // 60 FPS smoothing
        
        let newX = fusedPosition.x + avgX
        let newY = fusedPosition.y + avgY
        
        // Apply smoothing
        fusedPosition.x = fusedPosition.x * (1.0 - smoothing) + newX * smoothing
        fusedPosition.y = fusedPosition.y * (1.0 - smoothing) + newY * smoothing
        
        // Get screen bounds and clamp
        let screenWidth = getScreenWidth()
        let screenHeight = getScreenHeight()
        fusedPosition.x = max(0, min(fusedPosition.x, Double(screenWidth) - 1))
        fusedPosition.y = max(0, min(fusedPosition.y, Double(screenHeight) - 1))
        
        // Clear deltas after processing
        for key in mouseDeltas.keys {
            mouseDeltas[key] = MouseDelta()
        }
        
        // Move cursor to fused position
        setCursorPosition(x: Int32(fusedPosition.x), y: Int32(fusedPosition.y))
        
        lastUpdateTime = currentTime
    }
    
    // Public methods for mode switching and information
    func toggleMode() {
        useIndividualMode.toggle()
        print("🔄 Mode switched to: \(useIndividualMode ? "Individual Mouse Control" : "Fused Triangulation")")
    }
    
    func getIndividualMousePositions() -> [String: MousePosition] {
        var positions: [String: MousePosition] = [:]
        for (deviceId, position) in mousePositions {
            positions["Mouse_\(deviceId)"] = position
        }
        return positions
    }
    
    func getActiveMouse() -> String? {
        guard let activeMouse = activeMouse else { return nil }
        return "Mouse_\(activeMouse)"
    }
    
    func getMode() -> String {
        return useIndividualMode ? "Individual" : "Fused"
    }
    
    func run() {
        print("Enhanced multi-mouse triangulation active (Windows).")
        print("Features: Weighted averaging, activity tracking, smoothing")
        print("🎮 Individual mouse coordinates tracking enabled")
        print("")
        print("📋 Controls:")
        print("- Press 'M' to toggle between Individual and Fused modes")
        print("- Press 'I' to show individual mouse positions")
        print("- Press 'A' to show active mouse")
        print("- Press 'Ctrl+C' to exit")
        print("")
        print("Current mode: \(getMode())")
        
        // Set up keyboard monitoring for mode switching
        DispatchQueue.global(qos: .background).async {
            self.monitorKeyboard()
        }
        
        // Start Windows message loop
        startWindowsMessageLoop()
    }
    
    private func monitorKeyboard() {
        // Simple keyboard monitoring for mode switching
        while true {
            if let input = readLine() {
                switch input.lowercased() {
                case "m":
                    DispatchQueue.main.async {
                        self.toggleMode()
                    }
                case "i":
                    DispatchQueue.main.async {
                        self.printIndividualPositions()
                    }
                case "a":
                    DispatchQueue.main.async {
                        self.printActiveMouse()
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func printIndividualPositions() {
        print("📊 Individual Mouse Positions:")
        let positions = getIndividualMousePositions()
        for (device, position) in positions {
            print("  🐭 \(device): (\(Int(position.x)), \(Int(position.y)))")
        }
        print("")
    }
    
    private func printActiveMouse() {
        if let activeMouse = getActiveMouse() {
            print("🎯 Active Mouse: \(activeMouse)")
        } else {
            print("🎯 No active mouse (using fused mode)")
        }
        print("")
    }
    
    // Windows-specific C++ bridge functions
    private func createWindowsHIDManager() -> UnsafeMutableRawPointer? {
        // This will be implemented in C++ and called via Swift C interop
        return createWindowsHIDManagerNative()
    }
    
    private func startWindowsMessageLoop() {
        // Start Windows message loop for HID input processing
        startWindowsMessageLoopNative()
    }
    
    private func getScreenWidth() -> Int32 {
        return getScreenWidthNative()
    }
    
    private func getScreenHeight() -> Int32 {
        return getScreenHeightNative()
    }
    
    private func setCursorPosition(x: Int32, y: Int32) {
        setCursorPositionNative(x: x, y: y)
    }
}

// C++ bridge function declarations
@_silgen_name("createWindowsHIDManagerNative")
func createWindowsHIDManagerNative() -> UnsafeMutableRawPointer?

@_silgen_name("startWindowsMessageLoopNative")
func startWindowsMessageLoopNative()

@_silgen_name("getScreenWidthNative")
func getScreenWidthNative() -> Int32

@_silgen_name("getScreenHeightNative")
func getScreenHeightNative() -> Int32

@_silgen_name("setCursorPositionNative")
func setCursorPositionNative(x: Int32, y: Int32)
