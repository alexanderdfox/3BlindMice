#pragma once

#include <windows.h>
#include <winuser.h>
#include <hidusage.h>
#include <functional>
#include <unordered_map>

// Windows HID Manager for multi-mouse support
class WindowsHIDManager {
public:
    WindowsHIDManager();
    ~WindowsHIDManager();
    
    // Initialize the HID manager
    bool initialize();
    
    // Start the message loop for HID input
    void startMessageLoop();
    
    // Register callback for mouse input
    void setMouseInputCallback(std::function<void(UINT32, INT32, INT32)> callback);
    
    // Register callback for scroll input
    void setScrollInputCallback(std::function<void(UINT32, INT32)> callback);
    
    // Get screen dimensions
    INT32 getScreenWidth();
    INT32 getScreenHeight();
    
    // Set cursor position
    void setCursorPosition(INT32 x, INT32 y);
    
    // Check if running as administrator
    bool isRunningAsAdministrator();

private:
    HWND m_hwnd;
    bool m_initialized;
    std::function<void(UINT32, INT32, INT32)> m_mouseCallback;
    std::function<void(UINT32, INT32)> m_scrollCallback;
    
    // Window procedure for handling messages
    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
    
    // Handle raw input
    void handleRawInput(LPARAM lParam);
    
    // Register for raw input
    bool registerRawInputDevices();
};

// C interface for Swift interop
extern "C" {
    // Create Windows HID Manager
    void* createWindowsHIDManagerNative();
    
    // Start Windows message loop
    void startWindowsMessageLoopNative();
    
    // Get screen dimensions
    INT32 getScreenWidthNative();
    INT32 getScreenHeightNative();
    
    // Set cursor position
    void setCursorPositionNative(INT32 x, INT32 y);
    
    // Check administrator privileges
    bool isRunningAsAdministratorNative();
}
