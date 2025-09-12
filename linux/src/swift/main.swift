import Foundation

// Main entry point for Linux version
print("🐭 3 Blind Mice - Linux Edition")
print("=================================")
print("Multi-mouse triangulation for Linux")
print("")

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

// Linux-specific function to check permissions
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
