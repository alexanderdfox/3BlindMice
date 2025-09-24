import Foundation

// Linux-specific mouse position structure
struct MousePosition {
    var x: Double
    var y: Double
    
    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
}

// Linux-specific mouse delta structure
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
    private var mouseRotations: [UInt32: Double] = [:] // Mouse rotation tracking
    private var fusedPosition = MousePosition(x: 0, y: 0) // Will be initialized to screen center
    private var lastUpdateTime = Date()
    private var smoothingFactor: Double = 0.7
    private var useIndividualMode = false
    private var activeMouse: UInt32? = nil
    
    // Linux-specific evdev manager handle
    private var evdevManagerHandle: UnsafeMutableRawPointer? = nil
    
    init() {
        // Initialize fused position to screen center
        let screenWidth = getScreenWidth()
        let screenHeight = getScreenHeight()
        fusedPosition = MousePosition(x: Double(screenWidth) / 2.0, y: Double(screenHeight) / 2.0)
        
        print("🐭 Enhanced Multi-Mouse Triangulation System (Linux)")
        print("===================================================")
        print("Features: Weighted averaging, activity tracking, smoothing")
        print("")
        
        // Initialize Linux evdev manager
        initializeLinuxEvdevManager()
    }
    
    private func initializeLinuxEvdevManager() {
        // Initialize Linux evdev interface
        evdevManagerHandle = createLinuxEvdevManager()
        
        if evdevManagerHandle == nil {
            print("❌ Failed to initialize Linux evdev Manager")
            print("")
            print("🔒 Permission Issue Detected!")
            print("=============================")
            print("This is a Linux security feature. You need proper device permissions.")
            print("")
            print("📋 How to fix:")
            print("1. Add user to input group: sudo usermod -a -G input $USER")
            print("2. Install udev rules: sudo cp udev/99-threeblindmice.rules /etc/udev/rules.d/")
            print("3. Reload udev: sudo udevadm control --reload-rules")
            print("4. Logout and login again")
            print("")
            print("💡 Alternative: Run with sudo (not recommended)")
            print("")
            return
        }
        
        print("✅ Linux evdev Manager initialized successfully")
        print("🎯 Ready to detect mouse movements")
        print("")
    }
    
    func handleInput(deviceId: UInt32, deltaX: Int32, deltaY: Int32) {
        let currentTime = Date()
        
        // Update audit/logging here if needed

        // Update mouse activity timestamp
        mouseActivity[deviceId] = currentTime
        
        // Initialize mouse weight and position if not set
        if mouseWeights[deviceId] == nil {
            mouseWeights[deviceId] = 1.0
        }
        if mousePositions[deviceId] == nil {
            // Initialize mouse position to screen center
            let screenWidth = getScreenWidth()
            let screenHeight = getScreenHeight()
            mousePositions[deviceId] = MousePosition(x: Double(screenWidth) / 2.0, y: Double(screenHeight) / 2.0)
        }
        if mouseRotations[deviceId] == nil {
            mouseRotations[deviceId] = 0.0
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
    
    // Handle scroll wheel input for cursor rotation
    func handleScrollInput(deviceId: UInt32, scrollDelta: Int32) {
        let currentTime = Date()
        
        // Update mouse activity timestamp
        mouseActivity[deviceId] = currentTime
        
        // Initialize rotation if not set
        if mouseRotations[deviceId] == nil {
            mouseRotations[deviceId] = 0.0
        }
        
        // Update rotation based on scroll wheel
        let rotationDelta = Double(scrollDelta) * 15.0 // 15 degrees per scroll step
        mouseRotations[deviceId] = (mouseRotations[deviceId] ?? 0.0) + rotationDelta
        
        // Normalize rotation to 0-360 degrees
        mouseRotations[deviceId] = mouseRotations[deviceId]!.truncatingRemainder(dividingBy: 360.0)
        if mouseRotations[deviceId]! < 0 {
            mouseRotations[deviceId]! += 360.0
        }
        
        print("🔄 Mouse rotation: \(Int(mouseRotations[deviceId]!))°")
    }
    
    private func updateIndividualMousePosition(deviceId: UInt32, delta: MouseDelta) {
        guard let currentPos = mousePositions[deviceId] else { return }
        
        let newX = currentPos.x + Double(delta.x)
        let newY = currentPos.y + Double(delta.y)
        
        // Use multi-display support for Linux
        let displayManager = LinuxDisplayManager.shared
        if let display = displayManager.getDisplayAt(x: Int32(newX), y: Int32(newY)) {
            let clampedCoords = displayManager.clampToDisplayBounds(x: Int32(newX), y: Int32(newY), display: display)
            mousePositions[deviceId] = MousePosition(x: Double(clampedCoords.x), y: Double(clampedCoords.y))
        } else if let primaryDisplay = displayManager.getPrimaryDisplay() {
            let clampedCoords = displayManager.clampToDisplayBounds(x: Int32(newX), y: Int32(newY), display: primaryDisplay)
            mousePositions[deviceId] = MousePosition(x: Double(clampedCoords.x), y: Double(clampedCoords.y))
        } else {
            // Fallback to legacy single-screen bounds
            let screenWidth = getScreenWidth()
            let screenHeight = getScreenHeight()
            mousePositions[deviceId] = MousePosition(
                x: max(0, min(newX, Double(screenWidth) - 1)),
                y: max(0, min(newY, Double(screenHeight) - 1))
            )
        }
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
        
        // Use multi-display support for clamping
        let displayManager = LinuxDisplayManager.shared
        if let display = displayManager.getDisplayAt(x: Int32(fusedPosition.x), y: Int32(fusedPosition.y)) {
            let clampedCoords = displayManager.clampToDisplayBounds(x: Int32(fusedPosition.x), y: Int32(fusedPosition.y), display: display)
            fusedPosition.x = Double(clampedCoords.x)
            fusedPosition.y = Double(clampedCoords.y)
        } else if let primaryDisplay = displayManager.getPrimaryDisplay() {
            let clampedCoords = displayManager.clampToDisplayBounds(x: Int32(fusedPosition.x), y: Int32(fusedPosition.y), display: primaryDisplay)
            fusedPosition.x = Double(clampedCoords.x)
            fusedPosition.y = Double(clampedCoords.y)
        } else {
            // Fallback to legacy single-screen bounds
            let screenWidth = getScreenWidth()
            let screenHeight = getScreenHeight()
            fusedPosition.x = max(0, min(fusedPosition.x, Double(screenWidth) - 1))
            fusedPosition.y = max(0, min(fusedPosition.y, Double(screenHeight) - 1))
        }
        
        // Clear deltas after processing
        for key in mouseDeltas.keys {
            mouseDeltas[key] = MouseDelta()
        }
        
        // Move cursor to fused position
        setCursorPosition(x: Int32(fusedPosition.x), y: Int32(fusedPosition.y))
        
        // Update GUI if available
        gui_update(fusedPosition.x, fusedPosition.y)
        
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
    
    // Get rotation for specific mouse
    func getMouseRotation(for deviceId: UInt32) -> Double {
        return mouseRotations[deviceId] ?? 0.0
    }
    
    // Get all mouse rotations
    func getAllMouseRotations() -> [UInt32: Double] {
        return mouseRotations
    }
    
    func run() {
        print("Enhanced multi-mouse triangulation active (Linux).")
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
        _ = gui_init(800, 600, "3 Blind Mice - Linux GUI")
        
        // Set up keyboard monitoring for mode switching
        DispatchQueue.global(qos: .background).async {
            self.monitorKeyboard()
        }
        
        // Start Linux event loop
        startLinuxEventLoop()
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
            let rotation = mouseRotations.first { "Mouse_\($0.key)" == device }?.value ?? 0.0
            print("  🐭 \(device): (\(Int(position.x)), \(Int(position.y))) Rotation: \(Int(rotation))°")
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
    
    // HIPAA-related methods removed for Linux build simplification
    
    // Linux-specific C bridge functions
    private func createLinuxEvdevManager() -> UnsafeMutableRawPointer? {
        // This will be implemented in C and called via Swift C interop
        return createLinuxEvdevManagerNative()
    }
    
    private func startLinuxEventLoop() {
        // Start Linux event loop for evdev input processing
        startLinuxEventLoopNative()
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

// C bridge function declarations
@_silgen_name("createLinuxEvdevManagerNative")
func createLinuxEvdevManagerNative() -> UnsafeMutableRawPointer?

@_silgen_name("startLinuxEventLoopNative")
func startLinuxEventLoopNative()

@_silgen_name("getScreenWidthNative")
func getScreenWidthNative() -> Int32

@_silgen_name("getScreenHeightNative")
func getScreenHeightNative() -> Int32

@_silgen_name("setCursorPositionNative")
func setCursorPositionNative(x: Int32, y: Int32)

@_silgen_name("gui_init")
func gui_init(_ width: Int32, _ height: Int32, _ title: UnsafePointer<CChar>!) -> Int32

@_silgen_name("gui_update")
func gui_update(_ host_x: Double, _ host_y: Double)

@_silgen_name("gui_close")
func gui_close()

// Date extension is defined in HIPAASecurity.swift
