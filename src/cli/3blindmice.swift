import Foundation
import IOKit.hid
import AppKit
import CoreGraphics

class MultiMouseManager {
	private var hidManager: IOHIDManager!
	private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
	private var mouseWeights: [IOHIDDevice: Double] = [:]
	private var mouseActivity: [IOHIDDevice: Date] = [:]
	private var fusedPosition = CGPoint(x: 500, y: 500)
	private var lastUpdateTime = Date()
	private var smoothingFactor: Double = 0.7

	init() {
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

	func run() {
		print("Enhanced multi-mouse triangulation active.")
		print("Features: Weighted averaging, activity tracking, smoothing")
		CFRunLoopRun()
	}
}

let manager = MultiMouseManager()
manager.run()