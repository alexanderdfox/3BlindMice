import SwiftUI
import AppKit
import IOKit.hid
import CoreGraphics

// MARK: - Display Manager
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

// MARK: - Notification Extensions
extension Notification.Name {
    static let emojiUpdated = Notification.Name("emojiUpdated")
}

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
    var emojiManager: EmojiManager!
    @Published var isActive = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use the high-quality icon.png for system tray
            if let iconImage = loadSystemTrayIcon() {
                button.image = iconImage
            } else {
                // Fallback to emoji if icon.png is not available
                let emojiImage = createEmojiImage("🐭", size: NSSize(width: 18, height: 18))
                button.image = emojiImage
            }
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
        emojiManager = EmojiManager()
        
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
    
    private func loadSystemTrayIcon() -> NSImage? {
        // Try multiple approaches to load the icon
        
        // First, try to load from app bundle resources
        if let iconImage = NSImage(named: "icon") {
            return resizeImageForSystemTray(iconImage)
        }
        
        // Second, try to load from the app bundle path
        if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png"),
           let iconImage = NSImage(contentsOfFile: iconPath) {
            print("✅ Loaded system tray icon from bundle path")
            return resizeImageForSystemTray(iconImage)
        }
        
        // Third, try to load from the app's main bundle
        let bundlePath = Bundle.main.bundlePath
        if let iconImage = NSImage(contentsOfFile: "\(bundlePath)/Contents/Resources/icon.png") {
            print("✅ Loaded system tray icon from app bundle")
            return resizeImageForSystemTray(iconImage)
        }
        
        print("⚠️  icon.png not found in app bundle")
        return nil
    }
    
    private func resizeImageForSystemTray(_ image: NSImage) -> NSImage {
        // Resize to appropriate system tray size (18x18 points)
        let traySize = NSSize(width: 18, height: 18)
        let resizedImage = NSImage(size: traySize)
        
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: traySize))
        resizedImage.unlockFocus()
        
        // Set template mode for proper system tray appearance
        resizedImage.isTemplate = true
        
        return resizedImage
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
    @State private var individualPositions: [String: CGPoint] = [:]
    @State private var currentMode = "Fused"
    @State private var activeMouse = "None"
    @State private var mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint)] = []
    @State private var showDetailedInfo = false
    @State private var showEmojiSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                StatusView(connectedMice: connectedMice, currentMode: currentMode, isActive: appDelegate.isActive)
                ControlButtonsView(appDelegate: appDelegate, showDetailedInfo: $showDetailedInfo, showEmojiSettings: $showEmojiSettings)
                CursorPositionView(cursorPosition: cursorPosition)
                
                if !individualPositions.isEmpty {
                    IndividualMousePositionsView(
                        individualPositions: individualPositions,
                        activeMouse: activeMouse,
                        mouseInfo: mouseInfo,
                        timeAgoString: timeAgoString,
                        emojiManager: appDelegate.emojiManager
                    )
                }
                
                if showDetailedInfo && !mouseInfo.isEmpty {
                    DetailedMouseInfoView(
                        mouseInfo: mouseInfo,
                        activeMouse: activeMouse,
                        timeAgoString: timeAgoString,
                        emojiManager: appDelegate.emojiManager
                    )
                }
                
                if showEmojiSettings {
                    EmojiSettingsView(emojiManager: appDelegate.emojiManager, connectedDevices: Array(individualPositions.keys))
                }
                
                // Add some bottom padding for better scrolling experience
                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(width: 350, height: 600)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                updateUI()
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        if timeInterval < 1 {
            return "Now"
        } else if timeInterval < 60 {
            return "\(Int(timeInterval))s ago"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))m ago"
        } else {
            return "\(Int(timeInterval / 3600))h ago"
        }
    }
    
    private func updateUI() {
        connectedMice = appDelegate.multiMouseManager?.connectedMiceCount ?? 0
        cursorPosition = appDelegate.multiMouseManager?.currentPosition ?? CGPoint(x: 500, y: 500)
        individualPositions = appDelegate.multiMouseManager?.getIndividualMousePositions() ?? [:]
        currentMode = appDelegate.multiMouseManager?.getMode() ?? "Fused"
        activeMouse = appDelegate.multiMouseManager?.getActiveMouse() ?? "None"
        mouseInfo = appDelegate.multiMouseManager?.getMouseInfo() ?? []
    }
}

// MARK: - Subviews
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cursorarrow.fill")
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
    }
}

struct StatusView: View {
    let connectedMice: Int
    let currentMode: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isActive ? "circle.fill" : "circle")
                    .foregroundColor(isActive ? .green : .red)
                Text(isActive ? "Active" : "Inactive")
                    .fontWeight(.medium)
            }
            
            HStack {
                Image(systemName: "cursorarrow")
                    .foregroundColor(.blue)
                Text("\(connectedMice) mice connected")
                    .fontWeight(.medium)
            }
            
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.orange)
                Text("Mode: \(currentMode)")
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ControlButtonsView: View {
    @ObservedObject var appDelegate: AppDelegate
    @Binding var showDetailedInfo: Bool
    @Binding var showEmojiSettings: Bool
    
    var body: some View {
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
                appDelegate.multiMouseManager?.toggleMode()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Toggle Mode")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!appDelegate.isActive)
            
            Button(action: {
                showDetailedInfo.toggle()
            }) {
                HStack {
                    Image(systemName: showDetailedInfo ? "eye.slash" : "eye")
                    Text(showDetailedInfo ? "Hide Details" : "Show Details")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!appDelegate.isActive)
            
            Button(action: {
                showEmojiSettings.toggle()
            }) {
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Custom Emojis")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
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
    }
}

struct CursorPositionView: View {
    let cursorPosition: CGPoint
    
    var body: some View {
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
    }
}

struct IndividualMousePositionsView: View {
    let individualPositions: [String: CGPoint]
    let activeMouse: String
    let mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint)]
    let timeAgoString: (Date) -> String
    let emojiManager: EmojiManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Individual Mouse Positions")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(individualPositions.keys.sorted()), id: \.self) { device in
                        if let position = individualPositions[device] {
                            VStack(spacing: 4) {
                                HStack {
                                    Text(emojiManager.getEmoji(for: device))
                                        .font(.title2)
                                        .foregroundColor(device == activeMouse ? .green : .gray)
                                    Text(device.prefix(8) + "...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("(\(Int(position.x)), \(Int(position.y)))")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                
                                if let mouseInfo = mouseInfo.first(where: { $0.device == device }) {
                                    HStack {
                                        Text("Weight: \(String(format: "%.2f", mouseInfo.weight))")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                        Spacer()
                                        if let activity = mouseInfo.activity {
                                            Text("Active: \(timeAgoString(activity))")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        } else {
                                            Text("Inactive")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(device == activeMouse ? Color.green.opacity(0.1) : Color.clear)
                            .cornerRadius(4)
                        }
                    }
                }
            }
            .frame(maxHeight: 100)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DetailedMouseInfoView: View {
    let mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint)]
    let activeMouse: String
    let timeAgoString: (Date) -> String
    let emojiManager: EmojiManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Detailed Mouse Information")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(mouseInfo.enumerated()), id: \.offset) { index, info in
                        VStack(spacing: 4) {
                            HStack {
                                Text(emojiManager.getEmoji(for: info.device))
                                    .font(.title2)
                                    .foregroundColor(info.device == activeMouse ? .green : .gray)
                                Text(info.device.prefix(8) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Weight: \(String(format: "%.2f", info.weight))")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            HStack {
                                Text("Position: (\(Int(info.position.x)), \(Int(info.position.y)))")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                                if let activity = info.activity {
                                    Text("Active: \(timeAgoString(activity))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("Inactive")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(info.device == activeMouse ? Color.green.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Emoji Management
class EmojiManager: ObservableObject {
    @Published var mouseEmojis: [String: String] = [:]
    private let defaultEmojis = ["🐭", "🐹", "🐰", "🐱", "🐶", "🐸", "🐵", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐙", "🦄", "🦋", "🐞", "🦕", "🦖", "🦒"]
    
    init() {
        loadEmojiPreferences()
    }
    
    func getEmoji(for device: String) -> String {
        if let customEmoji = mouseEmojis[device] {
            return customEmoji
        }
        
        // Find the next available default emoji
        let usedEmojis = Set(mouseEmojis.values)
        for emoji in defaultEmojis {
            if !usedEmojis.contains(emoji) {
                return emoji
            }
        }
        
        // If all default emojis are used, return the first one
        return defaultEmojis.first ?? "🐭"
    }
    
    func setEmoji(for device: String, emoji: String) {
        mouseEmojis[device] = emoji
        saveEmojiPreferences()
        
        // Notify that emoji was updated (for cursor updates)
        NotificationCenter.default.post(name: .emojiUpdated, object: device)
    }
    
    func resetEmoji(for device: String) {
        mouseEmojis.removeValue(forKey: device)
        saveEmojiPreferences()
    }
    
    func getDefaultEmojis() -> [String] {
        return defaultEmojis
    }
    
    private func loadEmojiPreferences() {
        if let data = UserDefaults.standard.data(forKey: "MouseEmojis"),
           let emojis = try? JSONDecoder().decode([String: String].self, from: data) {
            mouseEmojis = emojis
        }
    }
    
    private func saveEmojiPreferences() {
        if let data = try? JSONEncoder().encode(mouseEmojis) {
            UserDefaults.standard.set(data, forKey: "MouseEmojis")
        }
    }
}

struct EmojiSettingsView: View {
    @ObservedObject var emojiManager: EmojiManager
    let connectedDevices: [String]
    @State private var selectedDevice: String = ""
    @State private var customEmoji: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Custom Mouse Emojis")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(connectedDevices.sorted(), id: \.self) { device in
                        HStack {
                            Text(emojiManager.getEmoji(for: device))
                                .font(.title2)
                            Text(device.prefix(8) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Reset") {
                                emojiManager.resetEmoji(for: device)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedDevice == device ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedDevice = device
                        }
                    }
                }
            }
            .frame(maxHeight: 100)
            
            Divider()
            
            VStack(spacing: 8) {
                Text("Quick Emoji Picker")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if selectedDevice.isEmpty {
                    Text("Select a mouse above to assign an emoji")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(emojiManager.getDefaultEmojis(), id: \.self) { emoji in
                        Button(action: {
                            if !selectedDevice.isEmpty {
                                emojiManager.setEmoji(for: selectedDevice, emoji: emoji)
                                selectedDevice = ""
                            }
                        }) {
                            Text(emoji)
                                .font(.title2)
                                .padding(8)
                                .background(selectedDevice.isEmpty ? Color.clear : Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .disabled(selectedDevice.isEmpty)
                    }
                }
                
                HStack {
                    Text("Custom:")
                        .font(.caption)
                    TextField("Enter emoji", text: $customEmoji)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                    
                    Button("Set") {
                        if !selectedDevice.isEmpty && !customEmoji.isEmpty {
                            emojiManager.setEmoji(for: selectedDevice, emoji: customEmoji)
                            selectedDevice = ""
                            customEmoji = ""
                        }
                    }
                    .font(.caption)
                    .disabled(selectedDevice.isEmpty || customEmoji.isEmpty)
                }
            }
        }
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(10)
    }
}

// Enhanced MultiMouseManager with improved triangulation
// MARK: - MultiMouseManager
class MultiMouseManager: ObservableObject {
    // MARK: - Private Properties
    private var hidManager: IOHIDManager!
    private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
    private var mousePositions: [IOHIDDevice: CGPoint] = [:] // Individual mouse positions
    private var mouseWeights: [IOHIDDevice: Double] = [:]
    private var mouseActivity: [IOHIDDevice: Date] = [:]
    private var fusedPosition = CGPoint(x: 500, y: 500)
    private var isRunning = false
    private var lastUpdateTime = Date()
    private var smoothingFactor: Double = 0.7 // Smoothing factor for position updates
    @Published var useIndividualMode = true // Toggle between individual and fused modes
    @Published var activeMouse: IOHIDDevice? // Currently active mouse in individual mode
    
    // Custom cursor cache
    private var customCursors: [String: NSCursor] = [:]
    
    // MARK: - Initialization
    init() {
        setupHIDManager()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .emojiUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let deviceString = notification.object as? String,
                  self.useIndividualMode,
                  let activeMouse = self.activeMouse,
                  String(describing: activeMouse) == deviceString else { return }
            
            // Update cursor for the active mouse
            if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
                let emoji = emojiManager.getEmoji(for: deviceString)
                self.setCustomCursor(for: activeMouse, emoji: emoji)
            }
        }
    }
    
    // MARK: - HID Management
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
        print("🎮 Individual mouse coordinates tracking enabled")
    }
    
    func stop() {
        isRunning = false
        print("Multi-mouse triangulation stopped")
    }
    
    // MARK: - Custom Cursor Management
    
    private func createCustomCursor(from emoji: String) -> NSCursor? {
        // Check cache first
        if let cachedCursor = customCursors[emoji] {
            return cachedCursor
        }
        
        // Create a custom cursor from emoji
        let size = CGSize(width: 32, height: 32)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create attributed string with emoji
        let attributedString = NSAttributedString(
            string: emoji,
            attributes: [
                .font: NSFont.systemFont(ofSize: 24),
                .foregroundColor: NSColor.black
            ]
        )
        
        // Calculate position to center the emoji
        let stringSize = attributedString.size()
        let x = (size.width - stringSize.width) / 2
        let y = (size.height - stringSize.height) / 2
        
        // Draw emoji
        attributedString.draw(at: CGPoint(x: x, y: y))
        
        image.unlockFocus()
        
        // Create cursor with custom hot spot (center of emoji)
        let cursor = NSCursor(image: image, hotSpot: CGPoint(x: 16, y: 16))
        
        // Cache the cursor
        customCursors[emoji] = cursor
        
        return cursor
    }
    
    // MARK: - Cursor Management
    func setCustomCursor(for device: IOHIDDevice, emoji: String) {
        guard let cursor = createCustomCursor(from: emoji) else { return }
        
        DispatchQueue.main.async {
            cursor.set()
        }
    }
    
    private func resetToDefaultCursor() {
        DispatchQueue.main.async {
            NSCursor.arrow.set()
        }
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
                
                // Initialize mouse weight and position if not set
                if mouseWeights[device] == nil {
                    mouseWeights[device] = 1.0
                }
                if mousePositions[device] == nil {
                    mousePositions[device] = CGPoint(x: 500, y: 500) // Default starting position
                }
                
                var delta = mouseDeltas[device] ?? (0, 0)
                if usage == 0x30 {
                    delta.x += intValue
                } else if usage == 0x31 {
                    delta.y += intValue
                }
                mouseDeltas[device] = delta
                
                // Update individual mouse position
                updateIndividualMousePosition(device: device, delta: delta)
                
                // Update mouse weights based on activity
                updateMouseWeights()
                
                // Handle cursor movement based on mode
                if useIndividualMode {
                    handleIndividualMode(device: device)
                } else {
                    fuseAndMoveCursor()
                }
            }
        }
    }
    
    // MARK: - Mouse Position Management
    private func updateIndividualMousePosition(device: IOHIDDevice, delta: (x: Int, y: Int)) {
        guard let currentPos = mousePositions[device] else { return }
        
        let newX = currentPos.x + CGFloat(delta.x)
        let newY = currentPos.y + CGFloat(delta.y)
        
        // Clamp to screen bounds using multi-display support
        let displayManager = DisplayManager.shared
        if let display = displayManager.getDisplayAt(x: newX, y: newY) {
            let clampedCoords = displayManager.clampToDisplayBounds(x: newX, y: newY, display: display)
            mousePositions[device] = CGPoint(x: clampedCoords.x, y: clampedCoords.y)
        } else {
            // Fallback to primary display
            if let primaryDisplay = displayManager.getPrimaryDisplay() {
                let clampedCoords = displayManager.clampToDisplayBounds(x: newX, y: newY, display: primaryDisplay)
                mousePositions[device] = CGPoint(x: clampedCoords.x, y: clampedCoords.y)
            } else {
                mousePositions[device] = CGPoint(x: newX, y: newY)
            }
        }
    }
    
    private func handleIndividualMode(device: IOHIDDevice) {
        // Set this as the active mouse
        DispatchQueue.main.async {
            self.activeMouse = device
        }
        
        // Move cursor to this mouse's position
        if let position = mousePositions[device] {
            CGWarpMouseCursorPosition(position)
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
            
            // Set custom cursor for this mouse
            let deviceString = String(describing: device)
            if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
                let emoji = emojiManager.getEmoji(for: deviceString)
                setCustomCursor(for: device, emoji: emoji)
            }
        }
        
        // Clear deltas after processing
        mouseDeltas[device] = (0, 0)
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
        
        // Apply smoothing to position updates using multi-display support
        let displayManager = DisplayManager.shared
        let timeDelta = currentTime.timeIntervalSince(lastUpdateTime)
        let smoothing = min(1.0, timeDelta * 60.0) // 60 FPS smoothing
        
        let newX = fusedPosition.x + CGFloat(avgX)
        let newY = fusedPosition.y + CGFloat(avgY) // Normal Y axis
        
        // Apply smoothing
        fusedPosition.x = fusedPosition.x * (1.0 - smoothing) + newX * smoothing
        fusedPosition.y = fusedPosition.y * (1.0 - smoothing) + newY * smoothing
        
        // Clamp to screen bounds using multi-display support
        if let display = displayManager.getDisplayAt(x: fusedPosition.x, y: fusedPosition.y) {
            let clampedCoords = displayManager.clampToDisplayBounds(x: fusedPosition.x, y: fusedPosition.y, display: display)
            fusedPosition.x = clampedCoords.x
            fusedPosition.y = clampedCoords.y
        } else {
            // Fallback to primary display
            if let primaryDisplay = displayManager.getPrimaryDisplay() {
                let clampedCoords = displayManager.clampToDisplayBounds(x: fusedPosition.x, y: fusedPosition.y, display: primaryDisplay)
                fusedPosition.x = clampedCoords.x
                fusedPosition.y = clampedCoords.y
            }
        }
            
            // Clear deltas after processing
            for key in mouseDeltas.keys {
                mouseDeltas[key] = (0, 0)
            }
            
            // Move cursor to fused position
            CGWarpMouseCursorPosition(fusedPosition)
            CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
            
            // Reset to default cursor in fused mode
            resetToDefaultCursor()
            
            lastUpdateTime = currentTime
        }
    
    // MARK: - Public Methods
    // Public methods for mode switching and information
    func toggleMode() {
        useIndividualMode.toggle()
        let modeName = useIndividualMode ? "Individual" : "Fused"
        print("🔄 Switched to \(modeName) Mode")
        print("📊 Individual Mode: Each mouse controls cursor independently")
        print("🔗 Fused Mode: All mice contribute to single cursor position")
        
        // Update cursor based on mode
        if useIndividualMode {
            // Set cursor for the most recently active mouse
            if let activeMouse = activeMouse {
                let deviceString = String(describing: activeMouse)
                if let emojiManager = (NSApplication.shared.delegate as? AppDelegate)?.emojiManager {
                    let emoji = emojiManager.getEmoji(for: deviceString)
                    setCustomCursor(for: activeMouse, emoji: emoji)
                }
            }
        } else {
            // Reset to default cursor in fused mode
            resetToDefaultCursor()
        }
    }
    
    func getIndividualMousePositions() -> [String: CGPoint] {
        var positions: [String: CGPoint] = [:]
        for (device, position) in mousePositions {
            positions[String(describing: device)] = position
        }
        return positions
    }
    
    func getActiveMouse() -> String? {
        guard let activeMouse = activeMouse else { return nil }
        return String(describing: activeMouse)
    }
    
    func getMode() -> String {
        return useIndividualMode ? "Individual" : "Fused"
    }
    
    // Get detailed mouse information for debugging
    func getMouseInfo() -> [(device: String, weight: Double, activity: Date?, position: CGPoint)] {
        return mouseDeltas.map { (device, _) in
            let deviceName = String(describing: device)
            let weight = mouseWeights[device] ?? 1.0
            let activity = mouseActivity[device]
            let position = mousePositions[device] ?? CGPoint(x: 0, y: 0)
            return (device: deviceName, weight: weight, activity: activity, position: position)
        }
    }
    
    func printIndividualPositions() {
        print("Individual Mouse Positions:")
        for (device, position) in mousePositions {
            print("Device: \(String(describing: device)), Position: (\(Int(position.x)), \(Int(position.y)))")
        }
    }
    
    // MARK: - Utility Methods
    func printActiveMouse() {
        if let active = activeMouse {
            print("Active Mouse: \(String(describing: active))")
        } else {
            print("No active mouse.")
        }
    }
    
    func printDetailedMouseInfo() {
        print("Detailed Mouse Information:")
        for (device, weight, activity, position) in getMouseInfo() {
            print("Device: \(device), Weight: \(weight), Activity: \(activity?.description ?? "N/A"), Position: (\(Int(position.x)), \(Int(position.y)))")
        }
    }
}
