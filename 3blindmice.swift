import Foundation
import IOKit.hid
import AppKit
import CoreGraphics

class MultiMouseManager {
	private var hidManager: IOHIDManager!
	private var mouseDeltas: [IOHIDDevice: (x: Int, y: Int)] = [:]
	private var fusedPosition = CGPoint(x: 500, y: 500)

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

				var delta = mouseDeltas[device] ?? (0, 0)
				if usage == 0x30 {
					delta.x += intValue
				} else if usage == 0x31 {
					delta.y += intValue
				}
				mouseDeltas[device] = delta

				fuseAndMoveCursor()
			}
		}
	}

	func fuseAndMoveCursor() {
		let count = mouseDeltas.count
		guard count > 0 else { return }

		let totalX = mouseDeltas.values.reduce(0) { $0 + $1.x }
		let totalY = mouseDeltas.values.reduce(0) { $0 + $1.y }

		let avgX = Double(totalX) / Double(count)
		let avgY = Double(totalY) / Double(count)

		if let screenFrame = NSScreen.main?.frame {
			fusedPosition.x += CGFloat(avgX)
			fusedPosition.y -= CGFloat(avgY)

			fusedPosition.x = max(0, min(fusedPosition.x, screenFrame.width - 1))
			fusedPosition.y = max(0, min(fusedPosition.y, screenFrame.height - 1))

			for key in mouseDeltas.keys {
				mouseDeltas[key] = (0, 0)
			}

			CGWarpMouseCursorPosition(fusedPosition)
			CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
		}
	}

	func run() {
		print("Multi-mouse triangulation active.")
		CFRunLoopRun()
	}
}

let manager = MultiMouseManager()
manager.run()