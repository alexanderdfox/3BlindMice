import Foundation

// Main entry point for Windows version
print("🐭 3 Blind Mice - Windows Edition")
print("==================================")
print("Multi-mouse triangulation for Windows")
print("")

// Check if running with administrator privileges
if !isRunningAsAdministrator() {
    print("⚠️  Warning: Not running as administrator")
    print("   Some features may not work properly")
    print("   For full functionality, run as administrator")
    print("")
}

// Initialize and run the multi-mouse manager
let manager = MultiMouseManager()
manager.run()

// Windows-specific function to check administrator privileges
func isRunningAsAdministrator() -> Bool {
    // This would be implemented via Windows API calls
    // For now, return true as a placeholder
    return true
}
