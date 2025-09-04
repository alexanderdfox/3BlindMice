import SwiftUI
import AppKit
import IOKit.hid
import CoreGraphics

@main
struct ThreeBlindMiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    var multiMouseManager: MultiMouseManager!
    @Published var isActive = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create a custom image with the mouse emoji
            let emojiImage = createEmojiImage("🐭", size: NSSize(width: 18, height: 18))
            button.image = emojiImage
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ControlPanelView(appDelegate: self))
        
        // Initialize multi-mouse manager
        multiMouseManager = MultiMouseManager()
        
        // Start the application
        print("3 Blind Mice - Multi-Mouse Triangulation")
        print("Running in system tray. Click the mouse icon to control.")
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func toggleMultiMouse() {
        isActive.toggle()
        if isActive {
            multiMouseManager.start()
        } else {
            multiMouseManager.stop()
        }
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func createEmojiImage(_ emoji: String, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Set up the text attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size.height * 0.8),
            .foregroundColor: NSColor.labelColor
        ]
        
        // Create attributed string
        let attributedString = NSAttributedString(string: emoji, attributes: attributes)
        
        // Calculate position to center the emoji
        let stringSize = attributedString.size()
        let x = (size.width - stringSize.width) / 2
        let y = (size.height - stringSize.height) / 2
        
        // Draw the emoji
        attributedString.draw(at: NSPoint(x: x, y: y))
        
        image.unlockFocus()
        return image
    }
}

struct ControlPanelView: View {
    @ObservedObject var appDelegate: AppDelegate
    @State private var connectedMice = 0
    @State private var cursorPosition = CGPoint(x: 500, y: 500)
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mouse.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("3 Blind Mice")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Multi-Mouse Triangulation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Status Section
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: appDelegate.isActive ? "circle.fill" : "circle")
                        .foregroundColor(appDelegate.isActive ? .green : .red)
                    Text(appDelegate.isActive ? "Active" : "Inactive")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "mouse")
                        .foregroundColor(.blue)
                    Text("\(connectedMice) mice connected")
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Control Section
            VStack(spacing: 15) {
                Button(action: {
                    appDelegate.toggleMultiMouse()
                }) {
                    HStack {
                        Image(systemName: appDelegate.isActive ? "stop.fill" : "play.fill")
                        Text(appDelegate.isActive ? "Stop Triangulation" : "Start Triangulation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appDelegate.isActive ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    appDelegate.quitApp()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Cursor Position Display
            VStack(spacing: 8) {
                Text("Cursor Position")
                    .font(.headline)
                
                HStack {
                    Text("X: \(Int(cursorPosition.x))")
                    Spacer()
                    Text("Y: \(Int(cursorPosition.y))")
                }
                .font(.caption)
                .padding(.horizontal)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 400)
        .onAppear {
            // Start timer to update UI
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                updateUI()
            }
        }
    }
    
    private func updateUI() {
        // Update connected mice count and cursor position from MultiMouseManager
        connectedMice = appDelegate.multiMouseManager?.connectedMiceCount ?? 0
        cursorPosition = appDelegate.multiMouseManager?.currentPosition ?? CGPoint(x: 500, y: 500)
    }
}

// Enhanced MultiMouseManager with improved triangulation
class MultiMouseManager: ObservableObject {
    private var hidManager: IOHIDManager!
    private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
    private var mouseWeights: [IOHIDDevice: Double] = [:]
    private var mouseActivity: [IOHIDDevice: Date] = [:]
    private var fusedPosition = CGPoint(x: 500, y: 500)
    private var isRunning = false
    private var lastUpdateTime = Date()
    private var smoothingFactor: Double = 0.7 // Smoothing factor for position updates
    
    init() {
        setupHIDManager()
    }
    
    private func setupHIDManager() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]
        
        IOHIDManagerSetDeviceMatching(hidManager, matchingDict as CFDictionary)
        
        let inputCallback: IOHIDValueCallback = { context, result, sender, value in
            let this = Unmanaged<MultiMouseManager>.fromOpaque(context!).takeUnretainedValue()
            this.handleInput(value: value)
        }
        
        IOHIDManagerRegisterInputValueCallback(hidManager, inputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        let result = IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            print("❌ Failed to open HID Manager")
            print("🔒 Permission Issue Detected!")
            print("=============================")
            print("This is a macOS security feature. You need to grant Input Monitoring permissions.")
            print("")
            print("📋 How to fix:")
            print("1. Open System Preferences → Security & Privacy → Privacy")
            print("2. Select 'Input Monitoring' from the left sidebar")
            print("3. Click the lock icon and enter your password")
            print("4. Click the '+' button and add ThreeBlindMice.app")
            print("5. Check the box next to ThreeBlindMice.app")
            print("6. Restart the application")
            print("")
            print("🚀 Quick fix:")
            print("open 'x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring'")
            print("")
            
            // Show a user-friendly alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Permission Required"
                alert.informativeText = "ThreeBlindMice needs Input Monitoring permission to access mouse devices.\n\nPlease grant permission in System Preferences and restart the app."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "OK")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring")!)
                }
            }
        } else {
            print("✅ HID Manager opened successfully")
            print("🎯 Ready to detect mouse movements")
        }
    }
    
    func start() {
        isRunning = true
        print("Enhanced multi-mouse triangulation started")
        print("Features: Weighted averaging, activity tracking, smoothing")
    }
    
    func stop() {
        isRunning = false
        print("Multi-mouse triangulation stopped")
    }
    
    // Get connected mice count for UI
    var connectedMiceCount: Int {
        return mouseDeltas.count
    }
    
    // Get current fused position for UI
    var currentPosition: CGPoint {
        return fusedPosition
    }
    
    func handleInput(value: IOHIDValue) {
        guard isRunning else { return }
        
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        
        if usagePage == UInt32(kHIDPage_GenericDesktop) {
            if usage == 0x30 || usage == 0x31 {
                let intValue = IOHIDValueGetIntegerValue(value)
                let device = IOHIDElementGetDevice(element)
                let currentTime = Date()
                
                // Update mouse activity timestamp
                mouseActivity[device] = currentTime
                
                // Initialize mouse weight if not set
                if mouseWeights[device] == nil {
                    mouseWeights[device] = 1.0
                }
                
                var delta = mouseDeltas[device] ?? (0, 0)
                if usage == 0x30 {
                    delta.x += intValue
                } else if usage == 0x31 {
                    delta.y += intValue
                }
                mouseDeltas[device] = delta
                
                // Update mouse weights based on activity
                updateMouseWeights()
                
                fuseAndMoveCursor()
            }
        }
    }
    
    private func updateMouseWeights() {
        let currentTime = Date()
        let activityTimeout: TimeInterval = 2.0 // 2 seconds timeout
        
        for (device, lastActivity) in mouseActivity {
            let timeSinceActivity = currentTime.timeIntervalSince(lastActivity)
            
            // Reduce weight for inactive mice
            if timeSinceActivity > activityTimeout {
                mouseWeights[device] = max(0.1, (mouseWeights[device] ?? 1.0) * 0.9)
            } else {
                // Increase weight for active mice
                mouseWeights[device] = min(2.0, (mouseWeights[device] ?? 1.0) * 1.1)
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
        
        for (device, delta) in mouseDeltas {
            let weight = mouseWeights[device] ?? 1.0
            weightedTotalX += Double(delta.x) * weight
            weightedTotalY += Double(delta.y) * weight
            totalWeight += weight
        }
        
        guard totalWeight > 0 else { return }
        
        let avgX = weightedTotalX / totalWeight
        let avgY = weightedTotalY / totalWeight
        
        if let screenFrame = NSScreen.main?.frame {
            // Apply smoothing to position updates
            let timeDelta = currentTime.timeIntervalSince(lastUpdateTime)
            let smoothing = min(1.0, timeDelta * 60.0) // 60 FPS smoothing
            
            			let newX = fusedPosition.x + CGFloat(avgX)
			let newY = fusedPosition.y + CGFloat(avgY) // Normal Y axis
            
            // Apply smoothing
            fusedPosition.x = fusedPosition.x * (1.0 - smoothing) + newX * smoothing
            fusedPosition.y = fusedPosition.y * (1.0 - smoothing) + newY * smoothing
            
            // Clamp to screen bounds
            fusedPosition.x = max(0, min(fusedPosition.x, screenFrame.width - 1))
            fusedPosition.y = max(0, min(fusedPosition.y, screenFrame.height - 1))
            
            // Clear deltas after processing
            for key in mouseDeltas.keys {
                mouseDeltas[key] = (0, 0)
            }
            
            // Move cursor to fused position
            CGWarpMouseCursorPosition(fusedPosition)
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
            
            lastUpdateTime = currentTime
        }
    }
    
    // Get detailed mouse information for debugging
    func getMouseInfo() -> [(device: String, weight: Double, activity: Date?)] {
        return mouseDeltas.map { (device, _) in
            let deviceName = String(describing: device)
            let weight = mouseWeights[device] ?? 1.0
            let activity = mouseActivity[device]
            return (device: deviceName, weight: weight, activity: activity)
        }
    }
}
