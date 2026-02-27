import SwiftUI
import AppKit
import IOKit.hid
import CoreGraphics
import QuartzCore

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

// MARK: - Emoji Cursor Overlay
/// Transparent overlay windows showing emoji cursors for each mouse, always on top.
final class EmojiCursorOverlayManager {
    private var cursorWindows: [String: NSWindow] = [:]
    private var fusedWindow: NSWindow?
    private let cursorSize: CGFloat = 36
    private var isShowing = false
    private var displayLink: CVDisplayLink?
    private weak var multiMouseManager: MultiMouseManager?
    private weak var emojiManager: EmojiManager?
    
    init(multiMouseManager: MultiMouseManager, emojiManager: EmojiManager) {
        self.multiMouseManager = multiMouseManager
        self.emojiManager = emojiManager
    }
    
    func show() {
        DispatchQueue.main.async {
            self.isShowing = true
            self.startDisplayLink()
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.isShowing = false
            self.stopDisplayLink()
            self.removeAllWindows()
        }
    }
    
    private func startDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let displayLink = link else { return }
        self.displayLink = displayLink
        
        CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, context -> CVReturn in
            guard let context = context else { return kCVReturnError }
            let manager = Unmanaged<EmojiCursorOverlayManager>.fromOpaque(context).takeUnretainedValue()
            // Defer to next run loop iteration to avoid layout recursion (layoutSubtreeIfNeeded during layout)
            DispatchQueue.main.async {
                DispatchQueue.main.async { manager.updateOverlays() }
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink)
    }
    
    private func stopDisplayLink() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
        displayLink = nil
    }
    
    private func updateOverlays() {
        guard isShowing,
              let multiMouse = multiMouseManager, let emojiMgr = emojiManager else {
            if !isShowing { removeAllWindows() }
            return
        }
        let data = multiMouse.getOverlayData()
        
        // Real cursor stays with first mouse position
        multiMouse.warpCursorToCurrentPosition()
        
        let sortedIds = data.individual.keys.sorted()
        if data.useIndividual {
            // Individual mode: all mice get emoji overlays; first mouse also has real cursor warped underneath
            for deviceId in sortedIds {
                guard let position = data.individual[deviceId] else { continue }
                let emoji = emojiMgr.getEmoji(for: deviceId)
                let rotation = data.individualRotations[deviceId] ?? 0.0
                updateOrCreateWindow(deviceId: deviceId, position: position, emoji: emoji, rotation: rotation)
            }
            removeFusedWindow()
            let overlayIds = Set(sortedIds)
            for id in cursorWindows.keys where !overlayIds.contains(id) {
                cursorWindows[id]?.orderOut(nil)
                cursorWindows.removeValue(forKey: id)
            }
        } else {
            // Fused / 3-body mode: real cursor at fused position, emoji for ALL mice at their positions
            for deviceId in sortedIds {
                guard let position = data.individual[deviceId] else { continue }
                let emoji = emojiMgr.getEmoji(for: deviceId)
                let rotation = data.individualRotations[deviceId] ?? 0.0
                updateOrCreateWindow(deviceId: deviceId, position: position, emoji: emoji, rotation: rotation)
            }
            removeFusedWindow()
            let overlayIds = Set(sortedIds)
            for id in cursorWindows.keys where !overlayIds.contains(id) {
                cursorWindows[id]?.orderOut(nil)
                cursorWindows.removeValue(forKey: id)
            }
        }
    }
    
    private func updateOrCreateWindow(deviceId: String, position: CGPoint, emoji: String, rotation: Double = 0) {
        let origin = convertToWindowOrigin(position)
        if let window = cursorWindows[deviceId] {
            window.setFrameOrigin(origin)
            updateEmojiView(in: window, emoji: emoji, rotation: rotation)
            window.orderFrontRegardless()
        } else {
            let window = makeCursorWindow(emoji: emoji, rotation: rotation)
            window.setFrameOrigin(origin)
            window.orderFrontRegardless()
            cursorWindows[deviceId] = window
        }
    }
    
    private func updateEmojiView(in window: NSWindow, emoji: String, rotation: Double) {
        guard let label = window.contentView?.subviews.first as? NSTextField,
              let layer = label.layer else { return }
        label.stringValue = emoji
        label.wantsLayer = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: cursorSize / 2, y: cursorSize / 2)
        layer.bounds = CGRect(x: 0, y: 0, width: cursorSize, height: cursorSize)
        layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(rotation * .pi / 180)))
        CATransaction.commit()
    }
    
    private func convertToWindowOrigin(_ screenPoint: CGPoint) -> NSPoint {
        // Screen coords: origin bottom-left. Window frame origin is bottom-left.
        // Center the cursor on the point.
        return NSPoint(x: screenPoint.x - cursorSize / 2, y: screenPoint.y - cursorSize / 2)
    }
    
    private func makeCursorWindow(emoji: String, rotation: Double = 0) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: cursorSize, height: cursorSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        
        let label = NSTextField(labelWithString: emoji)
        label.font = NSFont(name: "Apple Color Emoji", size: 28) ?? NSFont.systemFont(ofSize: 28)
        label.textColor = .black
        label.backgroundColor = .clear
        label.drawsBackground = false
        label.isBordered = false
        label.frame = NSRect(x: 0, y: 0, width: cursorSize, height: cursorSize)
        label.alignment = .center
        label.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        label.wantsLayer = true
        // Center pivot for rotation around emoji center
        label.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        label.layer?.position = CGPoint(x: cursorSize / 2, y: cursorSize / 2)
        label.layer?.bounds = CGRect(x: 0, y: 0, width: cursorSize, height: cursorSize)
        let radians = CGFloat(rotation * .pi / 180)
        label.layer?.setAffineTransform(CGAffineTransform(rotationAngle: radians))
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: cursorSize, height: cursorSize))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = CGColor.clear
        contentView.addSubview(label)
        
        window.contentView = contentView
        return window
    }
    
    private func removeAllWindows() {
        removeIndividualWindows()
        removeFusedWindow()
    }
    
    private func removeIndividualWindows() {
        for (_, window) in cursorWindows {
            window.orderOut(nil)
        }
        cursorWindows.removeAll()
    }
    
    private func removeFusedWindow() {
        fusedWindow?.orderOut(nil)
        fusedWindow = nil
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
    private var cursorOverlay: EmojiCursorOverlayManager!
    @Published var isActive = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance: prevent Metal flock conflict (errno 35) from multiple copies
        let bundleId = Bundle.main.bundleIdentifier ?? "com.threeblindmice.app"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        let otherInstances = running.filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if !otherInstances.isEmpty {
            otherInstances.first?.activate(options: .activateIgnoringOtherApps)
            NSApp.terminate(nil)
            return
        }

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
        
        // Initialize multi-mouse manager and emoji manager
        multiMouseManager = MultiMouseManager()
        emojiManager = EmojiManager()
        cursorOverlay = EmojiCursorOverlayManager(multiMouseManager: multiMouseManager, emojiManager: emojiManager)
        
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
            cursorOverlay.show()
        } else {
            cursorOverlay.hide()
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
    @State private var mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint, rotation: Double)] = []
    @State private var showDetailedInfo = false
    @State private var showEmojiSettings = false
    @State private var physicsBlendValue: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                StatusView(connectedMice: connectedMice, currentMode: currentMode, isActive: appDelegate.isActive)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(get: {
                        appDelegate.multiMouseManager?.physicsEnabled ?? false
                    }, set: { v in
                        appDelegate.multiMouseManager?.physicsEnabled = v
                    })) {
                        HStack {
                            Text("3-Body Mode")
                            Spacer()
                            Image(systemName: (appDelegate.multiMouseManager?.physicsEnabled ?? false) ? "circle.fill" : "circle")
                                .foregroundColor((appDelegate.multiMouseManager?.physicsEnabled ?? false) ? .blue : .gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(10)
                
                ControlButtonsView(appDelegate: appDelegate, showDetailedInfo: $showDetailedInfo, showEmojiSettings: $showEmojiSettings)
                CursorPositionView(cursorPosition: cursorPosition)
                
                if !individualPositions.isEmpty && !(appDelegate.multiMouseManager?.physicsEnabled ?? false) {
                    IndividualMousePositionsView(
                        individualPositions: individualPositions,
                        activeMouse: activeMouse,
                        mouseInfo: mouseInfo,
                        timeAgoString: timeAgoString,
                        emojiManager: appDelegate.emojiManager
                    )
                }
                
                if showDetailedInfo && !mouseInfo.isEmpty && !(appDelegate.multiMouseManager?.physicsEnabled ?? false) {
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
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(width: 350, height: 600)
        .onAppear {
            physicsBlendValue = (appDelegate.multiMouseManager?.physicsEnabled ?? false) ? 1.0 : 0.0
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                DispatchQueue.main.async { updateUI() }
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
            Image(systemName: "cursorarrow")
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
    let mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint, rotation: Double)]
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
                                        Text("Rotation: \(Int(mouseInfo.rotation))°")
                                            .font(.caption2)
                                            .foregroundColor(.purple)
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
    let mouseInfo: [(device: String, weight: Double, activity: Date?, position: CGPoint, rotation: Double)]
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
                                Text("Rotation: \(Int(info.rotation))°")
                                    .font(.caption)
                                    .foregroundColor(.purple)
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
    private var hasExclusiveHIDAccess = false // true when device seized; we must post synthetic clicks
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
    
    // Cursor rotation tracking
    private var mouseRotations: [IOHIDDevice: Double] = [:]
    private var cursorRotation: Double = 0.0 // Current cursor rotation in degrees
    
    // 3-body-inspired fusion state
    private var fusedVelocity = CGPoint(x: 0, y: 0)
    private let physicsDamping: CGFloat = 0.12  // velocity damping
    private let physicsGain: CGFloat = 1.0      // force gain from deltas
    private let maxSpeed: CGFloat = 1500.0      // pixels per second cap
    @Published var physicsEnabled: Bool = false {  // off = classic, on = 3-body physics
        didSet {
            // Physics visualization uses the fused cursor; force fused mode when enabled
            if physicsEnabled { useIndividualMode = false }
        }
    }
    
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
        ) { _ in
            // Emoji shown in overlay for additional mice; keep default cursor
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
        
        // Open with shared access initially; seizure happens in start() when user presses Start
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
        // Use shared access—seizing prevents mouse detection on many setups
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
    
    private func createCustomCursor(from emoji: String, rotation: Double = 0.0) -> NSCursor? {
        // Create cache key with rotation
        let cacheKey = "\(emoji)_\(Int(rotation))"
        
        // Check cache first
        if let cachedCursor = customCursors[cacheKey] {
            return cachedCursor
        }
        
        // Create a custom cursor from emoji
        let size = CGSize(width: 32, height: 32)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Apply rotation transformation
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rotationTransform = NSAffineTransform()
        rotationTransform.translateX(by: center.x, yBy: center.y)
        rotationTransform.rotate(byDegrees: rotation)
        rotationTransform.translateX(by: -center.x, yBy: -center.y)
        rotationTransform.concat()
        
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
        customCursors[cacheKey] = cursor
        
        return cursor
    }
    
    // MARK: - Cursor Management
    func setCustomCursor(for device: IOHIDDevice, emoji: String) {
        let rotation = mouseRotations[device] ?? 0.0
        guard let cursor = createCustomCursor(from: emoji, rotation: rotation) else { return }
        
        DispatchQueue.main.async {
            cursor.set()
        }
    }
    
    private func updateCursorRotation(device: IOHIDDevice) {
        guard let rotation = mouseRotations[device] else { return }
        cursorRotation = rotation
        if !useIndividualMode { updateFusedCursorRotation() }
    }
    
    private func updateFusedCursorRotation() {
        // Calculate weighted average rotation
        var weightedRotation: Double = 0.0
        var totalWeight: Double = 0.0
        
        for (device, rotation) in mouseRotations {
            let weight = mouseWeights[device] ?? 1.0
            weightedRotation += rotation * weight
            totalWeight += weight
        }
        
        if totalWeight > 0 {
            cursorRotation = weightedRotation / totalWeight
            // Normalize to 0-360 degrees
            cursorRotation = cursorRotation.truncatingRemainder(dividingBy: 360.0)
            if cursorRotation < 0 {
                cursorRotation += 360.0
            }
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
                    // Start each new mouse at the center of the screen
                    let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
                    let centerX = screenFrame.width / 2
                    let centerY = screenFrame.height / 2
                    mousePositions[device] = CGPoint(x: centerX, y: centerY)
                }
                if mouseRotations[device] == nil {
                    mouseRotations[device] = 0.0
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
            } else if usage == 0x38 { // Scroll wheel (kHIDUsage_GD_Wheel)
                let intValue = IOHIDValueGetIntegerValue(value)
                let device = IOHIDElementGetDevice(element)
                let currentTime = Date()
                
                // Update mouse activity timestamp
                mouseActivity[device] = currentTime
                
                // Initialize rotation if not set
                if mouseRotations[device] == nil {
                    mouseRotations[device] = 0.0
                }
                
                // Update rotation based on scroll wheel
                let rotationDelta = Double(intValue) * 15.0 // 15 degrees per scroll step
                mouseRotations[device] = (mouseRotations[device] ?? 0.0) + rotationDelta
                
                // Normalize rotation to 0-360 degrees
                mouseRotations[device] = mouseRotations[device]!.truncatingRemainder(dividingBy: 360.0)
                if mouseRotations[device]! < 0 {
                    mouseRotations[device]! += 360.0
                }
                
                updateCursorRotation(device: device)
                postScrollEvent(device: device, delta: Int32(intValue))
            }
        } else if usagePage == UInt32(kHIDPage_Button) {
            // Mouse buttons: 1=left, 2=right, 3=middle
            let buttonNum = Int(usage)
            guard buttonNum >= 1 && buttonNum <= 3 else { return }
            let value = IOHIDValueGetIntegerValue(value)
            let device = IOHIDElementGetDevice(element)
            let isDown = (value == 1)
            postMouseButtonEvent(device: device, button: buttonNum, isDown: isDown)
        }
    }
    
    /// Post synthetic mouse down/up at this mouse's position (so clicks land under emoji).
    private func postMouseButtonEvent(device: IOHIDDevice, button: Int, isDown: Bool) {
        guard hasExclusiveHIDAccess else { return }
        let position: CGPoint
        if useIndividualMode, let pos = mousePositions[device] {
            position = pos
        } else {
            position = fusedPosition
        }
        let (downType, upType, cgButton): (CGEventType, CGEventType, CGMouseButton)
        switch button {
        case 1: (downType, upType, cgButton) = (.leftMouseDown, .leftMouseUp, .left)
        case 2: (downType, upType, cgButton) = (.rightMouseDown, .rightMouseUp, .right)
        default: (downType, upType, cgButton) = (.otherMouseDown, .otherMouseUp, .center)
        }
        let eventType = isDown ? downType : upType
        guard let event = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: position, mouseButton: cgButton) else { return }
        event.setIntegerValueField(.mouseEventClickState, value: 1)
        event.post(tap: .cghidEventTap)
    }
    
    /// Post synthetic scroll at this mouse's position (so scroll lands under emoji).
    private func postScrollEvent(device: IOHIDDevice, delta: Int32) {
        guard hasExclusiveHIDAccess else { return }
        let position: CGPoint
        if useIndividualMode, let pos = mousePositions[device] {
            position = pos
        } else {
            position = fusedPosition
        }
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: CGScrollEventUnit.line, wheelCount: 1, wheel1: delta, wheel2: 0, wheel3: 0) else { return }
        event.location = position
        event.post(tap: .cghidEventTap)
    }
    
    // MARK: - Mouse Position Management
    private func updateIndividualMousePosition(device: IOHIDDevice, delta: (x: Int, y: Int)) {
        guard let currentPos = mousePositions[device] else { return }
        let sortedIds = mousePositions.keys.map { String(describing: $0) }.sorted()
        let isPrimaryMouse = sortedIds.first.map { String(describing: device) == $0 } ?? true
        let yDelta = isPrimaryMouse ? delta.y : -delta.y
        let newX = currentPos.x + CGFloat(delta.x)
        let newY = currentPos.y + CGFloat(yDelta)
        
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
        
        warpCursorToCurrentPosition()
        
        // Keep original default cursor; additional mice show emoji in overlay only
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
        
        updateFusedCursorRotation() // Keep fused emoji rotation in sync
        let currentTime = Date()
        let dt = max(1.0/240.0, currentTime.timeIntervalSince(lastUpdateTime)) // stable small timestep
        let displayManager = DisplayManager.shared
        
        // Compute classic fused target from absolute individual positions (weighted centroid)
        var weightedSumX: CGFloat = 0
        var weightedSumY: CGFloat = 0
        var totalWeight: CGFloat = 0
        for (device, pos) in mousePositions {
            let weight = CGFloat(mouseWeights[device] ?? 1.0)
            weightedSumX += pos.x * weight
            weightedSumY += pos.y * weight
            totalWeight += weight
        }
        var classicNext = fusedPosition
        if totalWeight > 0 {
            let centroidX = weightedSumX / totalWeight
            let centroidY = weightedSumY / totalWeight
            let smoothing = min(1.0, currentTime.timeIntervalSince(lastUpdateTime) * 8.0) // gentle smoothing toward centroid
            classicNext.x = fusedPosition.x * (1.0 - smoothing) + centroidX * smoothing
            classicNext.y = fusedPosition.y * (1.0 - smoothing) + centroidY * smoothing
        }
        
        if physicsEnabled {
            // 3-body-inspired physics: mice act as attractors, current fusedPosition is the host cursor
            // Force accumulates from each mouse position ~ weight / dist^2 toward that mouse
            let G: CGFloat = 0.5 // gravitational constant-like gain (tuned for visible motion)
            var forceX: CGFloat = 0
            var forceY: CGFloat = 0
            for (device, pos) in mousePositions {
                let dx = pos.x - fusedPosition.x
                let dy = pos.y - fusedPosition.y
                let distSq = max(25.0, dx*dx + dy*dy) // avoid huge forces at very small distances
                let weight = CGFloat(mouseWeights[device] ?? 1.0)
                let magnitude = G * weight / distSq
                forceX += magnitude * dx
                forceY += magnitude * dy
            }
            // Integrate with damping and speed cap
            fusedVelocity.x = (1.0 - physicsDamping) * fusedVelocity.x + forceX * CGFloat(dt)
            fusedVelocity.y = (1.0 - physicsDamping) * fusedVelocity.y + forceY * CGFloat(dt)
            let speed = sqrt(fusedVelocity.x * fusedVelocity.x + fusedVelocity.y * fusedVelocity.y)
            if speed > maxSpeed {
                let scale = maxSpeed / speed
                fusedVelocity.x *= scale
                fusedVelocity.y *= scale
            }
            fusedPosition.x += fusedVelocity.x * CGFloat(dt)
            fusedPosition.y += fusedVelocity.y * CGFloat(dt)

            // Safety: if physics force/velocity are too small, gently move toward centroid target
            let centroidTarget = classicNext
            let distToCentroidX = centroidTarget.x - fusedPosition.x
            let distToCentroidY = centroidTarget.y - fusedPosition.y
            let distToCentroid = sqrt(distToCentroidX*distToCentroidX + distToCentroidY*distToCentroidY)
            if speed < 0.01 && distToCentroid > 1.0 {
                let nudgeGain: CGFloat = 0.15
                fusedPosition.x = fusedPosition.x + distToCentroidX * nudgeGain
                fusedPosition.y = fusedPosition.y + distToCentroidY * nudgeGain
            }
        } else {
            fusedPosition = classicNext
        }
        
        // Toroidal wrap-around within the active display bounds
        if let display = displayManager.getDisplayAt(x: fusedPosition.x, y: fusedPosition.y) {
            let minX = display.frame.origin.x
            let minY = display.frame.origin.y
            let width = display.frame.width
            let height = display.frame.height
            func wrap(_ value: CGFloat, _ start: CGFloat, _ size: CGFloat) -> CGFloat {
                if size <= 0 { return start }
                let local = value - start
                let wrappedLocal = local.truncatingRemainder(dividingBy: size)
                let positive = wrappedLocal < 0 ? wrappedLocal + size : wrappedLocal
                return start + positive
            }
            let wrappedX = wrap(fusedPosition.x, minX, width)
            let wrappedY = wrap(fusedPosition.y, minY, height)
            fusedPosition = CGPoint(x: wrappedX, y: wrappedY)
        }
        
        // Clear deltas
        for key in mouseDeltas.keys { mouseDeltas[key] = (0, 0) }
        
        // Real mouse always matches first virtual mouse
        warpCursorToCurrentPosition()
        resetToDefaultCursor()
        lastUpdateTime = currentTime
    }

    // Back-compat for earlier slider: treat >0.5 as enabled
    func setPhysicsBlend(_ value: Double) { physicsEnabled = value > 0.5 }
    
    // MARK: - Public Methods
    // Public methods for mode switching and information
    func toggleMode() {
        useIndividualMode.toggle()
        let modeName = useIndividualMode ? "Individual" : "Fused"
        print("🔄 Switched to \(modeName) Mode")
        print("📊 Individual Mode: Each mouse controls cursor independently")
        print("🔗 Fused Mode: All mice contribute to single cursor position")
        
        // Keep default cursor in both modes
        resetToDefaultCursor()
    }
    
    func getIndividualMousePositions() -> [String: CGPoint] {
        var positions: [String: CGPoint] = [:]
        for (device, position) in mousePositions {
            positions[String(describing: device)] = position
        }
        return positions
    }
    
    /// Warp the system cursor: first mouse in individual mode, fused position in fused mode
    func warpCursorToCurrentPosition() {
        let position: CGPoint
        if useIndividualMode,
           let firstDevice = mousePositions.keys.min(by: { String(describing: $0) < String(describing: $1) }),
           let pos = mousePositions[firstDevice] {
            position = pos
        } else {
            position = fusedPosition
        }
        CGWarpMouseCursorPosition(position)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
    }
    
    /// Data for emoji cursor overlay: positions, rotations, and mode
    func getOverlayData() -> (individual: [String: CGPoint], individualRotations: [String: Double], fused: CGPoint, fusedRotation: Double, useIndividual: Bool) {
        var ind: [String: CGPoint] = [:]
        var rots: [String: Double] = [:]
        for (device, pos) in mousePositions {
            let key = String(describing: device)
            ind[key] = pos
            rots[key] = mouseRotations[device] ?? 0.0
        }
        return (ind, rots, fusedPosition, cursorRotation, useIndividualMode)
    }
    
    func getActiveMouse() -> String? {
        guard let activeMouse = activeMouse else { return nil }
        return String(describing: activeMouse)
    }
    
    func getMode() -> String {
        return useIndividualMode ? "Individual" : "Fused"
    }
    
    // Get detailed mouse information for debugging
    func getMouseInfo() -> [(device: String, weight: Double, activity: Date?, position: CGPoint, rotation: Double)] {
        return mouseDeltas.map { (device, _) in
            let deviceName = String(describing: device)
            let weight = mouseWeights[device] ?? 1.0
            let activity = mouseActivity[device]
            let position = mousePositions[device] ?? CGPoint(x: 0, y: 0)
            let rotation = mouseRotations[device] ?? 0.0
            return (device: deviceName, weight: weight, activity: activity, position: position, rotation: rotation)
        }
    }
    
    // Get current cursor rotation
    func getCurrentRotation() -> Double {
        return cursorRotation
    }
    
    // Get rotation for specific mouse
    func getMouseRotation(for device: String) -> Double {
        for (deviceObj, rotation) in mouseRotations {
            if String(describing: deviceObj) == device {
                return rotation
            }
        }
        return 0.0
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
        for (device, weight, activity, position, rotation) in getMouseInfo() {
            print("Device: \(device), Weight: \(weight), Activity: \(activity?.description ?? "N/A"), Position: (\(Int(position.x)), \(Int(position.y))), Rotation: \(Int(rotation))°")
        }
    }
}

