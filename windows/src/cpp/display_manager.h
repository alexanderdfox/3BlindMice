#pragma once

#include <windows.h>
#include <vector>
#include <string>

struct DisplayInfo {
    std::string id;
    std::string name;
    RECT frame;
    bool isPrimary;
    float scaleFactor;
    
    DisplayInfo(const std::string& id, const std::string& name, const RECT& frame, bool isPrimary, float scaleFactor = 1.0f)
        : id(id), name(name), frame(frame), isPrimary(isPrimary), scaleFactor(scaleFactor) {}
};

class WindowsDisplayManager {
public:
    static WindowsDisplayManager& getInstance();
    
    // Get all available displays
    std::vector<DisplayInfo> getAllDisplays();
    
    // Get primary display
    DisplayInfo* getPrimaryDisplay();
    
    // Get display at specific coordinates
    DisplayInfo* getDisplayAt(int x, int y);
    
    // Get display by ID
    DisplayInfo* getDisplayById(const std::string& id);
    
    // Get total screen bounds (union of all displays)
    RECT getTotalScreenBounds();
    
    // Convert global coordinates to display-relative coordinates
    struct DisplayCoordinates {
        DisplayInfo* display;
        int localX;
        int localY;
    };
    DisplayCoordinates convertToDisplayCoordinates(int globalX, int globalY);
    
    // Clamp coordinates to display bounds
    struct ClampedCoordinates {
        int x;
        int y;
    };
    ClampedCoordinates clampToDisplayBounds(int x, int y, const DisplayInfo& display);
    
    // Update display information
    void updateDisplays();
    
private:
    WindowsDisplayManager();
    ~WindowsDisplayManager();
    
    std::vector<DisplayInfo> displays;
    DisplayInfo* primaryDisplay;
    
    // Callback for EnumDisplayMonitors
    static BOOL CALLBACK MonitorEnumProc(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData);
    
    // Helper to get monitor info
    std::string getMonitorName(HMONITOR hMonitor);
    float getMonitorScaleFactor(HMONITOR hMonitor);
};

// C interface for Swift
extern "C" {
    struct CDisplayInfo {
        char id[256];
        char name[256];
        int x, y, width, height;
        int isPrimary;
        float scaleFactor;
    };
    
    int getDisplayCount();
    void getDisplayInfo(int index, CDisplayInfo* info);
    void getPrimaryDisplayInfo(CDisplayInfo* info);
    int getDisplayAt(int x, int y, CDisplayInfo* info);
    void getTotalScreenBounds(int* x, int* y, int* width, int* height);
    void clampToDisplayBounds(int x, int y, const CDisplayInfo* display, int* clampedX, int* clampedY);
}
