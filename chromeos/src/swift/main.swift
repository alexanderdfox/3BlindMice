import Foundation

// Main entry point for ChromeOS version
print("🐭 3 Blind Mice - ChromeOS Edition")
print("==================================")
print("Multi-mouse triangulation for ChromeOS")
print("")

// Check if running in Crostini
if !isRunningInCrostini() {
    print("⚠️  Warning: Not running in Crostini Linux environment")
    print("   Some features may not work properly")
    print("   For full functionality, enable Crostini: Settings → Linux (Beta)")
    print("")
    print("💡 Alternative: Use the Chrome Extension version")
    print("   Load the extension from chromeos/extension/ folder")
    print("")
}

// Check if running with proper permissions
if !isRunningWithPermissions() {
    print("⚠️  Warning: May not have proper device permissions")
    print("   Some features may not work properly")
    print("   For full functionality, ensure proper udev rules and group membership")
    print("")
}

// Initialize and run the multi-mouse manager
let manager = MultiMouseManager()
manager.run()

// ChromeOS-specific function to check if running in Crostini
func isRunningInCrostini() -> Bool {
    // Check for Crostini environment indicators
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["printenv", "CROSTINI"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    } catch {
        // If we can't check, assume we're in Crostini
        return true
    }
    
    return false
}

// ChromeOS-specific function to check permissions
func isRunningWithPermissions() -> Bool {
    // Check if user is in input group
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/id")
    process.arguments = ["-Gn"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("input")
        }
    } catch {
        // If we can't check, assume we have permissions
        return true
    }
    
    return false
}
