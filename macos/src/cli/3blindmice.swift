import Foundation
import IOKit.hid
import AppKit
import CoreGraphics

class MultiMouseManager {
	private var hidManager: IOHIDManager!
	private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
	private var mousePositions: [IOHIDDevice: CGPoint] = [:] // Individual mouse positions
	private var mouseWeights: [IOHIDDevice: Double] = [:]
	private var mouseActivity: [IOHIDDevice: Date] = [:]
	private var fusedPosition = CGPoint(x: 0, y: 0) // Will be initialized to screen center
	private var lastUpdateTime = Date()
	private var smoothingFactor: Double = 0.7
	private var useIndividualMode = false // Toggle between individual and fused modes
	private var activeMouse: IOHIDDevice? // Currently active mouse in individual mode

	init() {
		// Initialize fused position to screen center
		let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
		fusedPosition = CGPoint(x: screenFrame.width / 2, y: screenFrame.height / 2)
		
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
			print("Failed to open HID Manager")
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
		} else {
			print("✅ HID Manager opened successfully")
			print("🎯 Ready to detect mouse movements")
		}
	}

	func handleInput(value: IOHIDValue) {
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

	private func updateIndividualMousePosition(device: IOHIDDevice, delta: (x: Int, y: Int)) {
		guard let currentPos = mousePositions[device] else { return }
		
		let newX = currentPos.x + CGFloat(delta.x)
		let newY = currentPos.y + CGFloat(delta.y)
		
		// Clamp to screen bounds
		if let screenFrame = NSScreen.main?.frame {
			mousePositions[device] = CGPoint(
				x: max(0, min(newX, screenFrame.width - 1)),
				y: max(0, min(newY, screenFrame.height - 1))
			)
		} else {
			mousePositions[device] = CGPoint(x: newX, y: newY)
		}
	}

	private func handleIndividualMode(device: IOHIDDevice) {
		// Set this as the active mouse
		activeMouse = device
		
		// Move cursor to this mouse's position
		if let position = mousePositions[device] {
			CGWarpMouseCursorPosition(position)
			CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
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

	// Public methods for mode switching and information
	func toggleMode() {
		useIndividualMode.toggle()
		print("🔄 Mode switched to: \(useIndividualMode ? "Individual Mouse Control" : "Fused Triangulation")")
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

	func run() {
		print("Enhanced multi-mouse triangulation active.")
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
		
		CFRunLoopRun()
	}

	private func monitorKeyboard() {
		// Simple keyboard monitoring for mode switching
		// Note: This is a basic implementation. For production, consider using Carbon events
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
}

let manager = MultiMouseManager()
manager.run()