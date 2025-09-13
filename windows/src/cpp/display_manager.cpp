#include "display_manager.h"
#include <iostream>
#include <sstream>

WindowsDisplayManager& WindowsDisplayManager::getInstance() {
    static WindowsDisplayManager instance;
    return instance;
}

WindowsDisplayManager::WindowsDisplayManager() : primaryDisplay(nullptr) {
    updateDisplays();
}

WindowsDisplayManager::~WindowsDisplayManager() {
    // Cleanup if needed
}

std::vector<DisplayInfo> WindowsDisplayManager::getAllDisplays() {
    return displays;
}

DisplayInfo* WindowsDisplayManager::getPrimaryDisplay() {
    return primaryDisplay;
}

DisplayInfo* WindowsDisplayManager::getDisplayAt(int x, int y) {
    POINT point = {x, y};
    
    for (auto& display : displays) {
        if (PtInRect(&display.frame, point)) {
            return &display;
        }
    }
    
    return primaryDisplay;
}

DisplayInfo* WindowsDisplayManager::getDisplayById(const std::string& id) {
    for (auto& display : displays) {
        if (display.id == id) {
            return &display;
        }
    }
    return nullptr;
}

RECT WindowsDisplayManager::getTotalScreenBounds() {
    if (displays.empty()) {
        RECT defaultRect = {0, 0, 1920, 1080};
        return defaultRect;
    }
    
    RECT unionRect = displays[0].frame;
    for (const auto& display : displays) {
        UnionRect(&unionRect, &unionRect, &display.frame);
    }
    
    return unionRect;
}

WindowsDisplayManager::DisplayCoordinates WindowsDisplayManager::convertToDisplayCoordinates(int globalX, int globalY) {
    DisplayCoordinates result = {nullptr, globalX, globalY};
    
    if (DisplayInfo* display = getDisplayAt(globalX, globalY)) {
        result.display = display;
        result.localX = globalX - display->frame.left;
        result.localY = globalY - display->frame.top;
    }
    
    return result;
}

WindowsDisplayManager::ClampedCoordinates WindowsDisplayManager::clampToDisplayBounds(int x, int y, const DisplayInfo& display) {
    ClampedCoordinates result;
    result.x = max(display.frame.left, min(x, display.frame.right - 1));
    result.y = max(display.frame.top, min(y, display.frame.bottom - 1));
    return result;
}

void WindowsDisplayManager::updateDisplays() {
    displays.clear();
    primaryDisplay = nullptr;
    
    EnumDisplayMonitors(NULL, NULL, MonitorEnumProc, reinterpret_cast<LPARAM>(this));
    
    // Sort displays by position (left to right, top to bottom)
    std::sort(displays.begin(), displays.end(), [](const DisplayInfo& a, const DisplayInfo& b) {
        if (a.frame.left != b.frame.left) {
            return a.frame.left < b.frame.left;
        }
        return a.frame.top < b.frame.top;
    });
    
    std::cout << "🖥️  Updated displays: " << displays.size() << " found" << std::endl;
    for (size_t i = 0; i < displays.size(); ++i) {
        const auto& display = displays[i];
        std::cout << "   Display " << (i + 1) << ": " << display.name 
                  << " (" << (display.frame.right - display.frame.left) 
                  << "x" << (display.frame.bottom - display.frame.top) << ") "
                  << (display.isPrimary ? "[PRIMARY]" : "") << std::endl;
    }
}

BOOL CALLBACK WindowsDisplayManager::MonitorEnumProc(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) {
    WindowsDisplayManager* manager = reinterpret_cast<WindowsDisplayManager*>(dwData);
    
    MONITORINFOEX monitorInfo;
    monitorInfo.cbSize = sizeof(MONITORINFOEX);
    GetMonitorInfo(hMonitor, &monitorInfo);
    
    std::string monitorId = std::to_string(reinterpret_cast<uintptr_t>(hMonitor));
    std::string monitorName = manager->getMonitorName(hMonitor);
    bool isPrimary = (monitorInfo.dwFlags & MONITORINFOF_PRIMARY) != 0;
    float scaleFactor = manager->getMonitorScaleFactor(hMonitor);
    
    DisplayInfo display(monitorId, monitorName, *lprcMonitor, isPrimary, scaleFactor);
    manager->displays.push_back(display);
    
    if (isPrimary) {
        manager->primaryDisplay = &manager->displays.back();
    }
    
    return TRUE;
}

std::string WindowsDisplayManager::getMonitorName(HMONITOR hMonitor) {
    DISPLAY_DEVICE device;
    device.cb = sizeof(DISPLAY_DEVICE);
    
    if (EnumDisplayDevices(NULL, 0, &device, 0)) {
        return std::string(device.DeviceString);
    }
    
    return "Unknown Monitor";
}

float WindowsDisplayManager::getMonitorScaleFactor(HMONITOR hMonitor) {
    // Get DPI for the monitor
    UINT dpiX, dpiY;
    if (GetDpiForMonitor(hMonitor, MDT_EFFECTIVE_DPI, &dpiX, &dpiY) == S_OK) {
        return static_cast<float>(dpiX) / 96.0f; // 96 DPI is 100% scaling
    }
    
    return 1.0f; // Default scale factor
}

// C interface implementation
extern "C" {
    int getDisplayCount() {
        auto& manager = WindowsDisplayManager::getInstance();
        return static_cast<int>(manager.getAllDisplays().size());
    }
    
    void getDisplayInfo(int index, CDisplayInfo* info) {
        auto& manager = WindowsDisplayManager::getInstance();
        auto displays = manager.getAllDisplays();
        
        if (index >= 0 && index < static_cast<int>(displays.size())) {
            const auto& display = displays[index];
            strncpy_s(info->id, display.id.c_str(), sizeof(info->id) - 1);
            strncpy_s(info->name, display.name.c_str(), sizeof(info->name) - 1);
            info->x = display.frame.left;
            info->y = display.frame.top;
            info->width = display.frame.right - display.frame.left;
            info->height = display.frame.bottom - display.frame.top;
            info->isPrimary = display.isPrimary ? 1 : 0;
            info->scaleFactor = display.scaleFactor;
        }
    }
    
    void getPrimaryDisplayInfo(CDisplayInfo* info) {
        auto& manager = WindowsDisplayManager::getInstance();
        if (DisplayInfo* primary = manager.getPrimaryDisplay()) {
            strncpy_s(info->id, primary->id.c_str(), sizeof(info->id) - 1);
            strncpy_s(info->name, primary->name.c_str(), sizeof(info->name) - 1);
            info->x = primary->frame.left;
            info->y = primary->frame.top;
            info->width = primary->frame.right - primary->frame.left;
            info->height = primary->frame.bottom - primary->frame.top;
            info->isPrimary = 1;
            info->scaleFactor = primary->scaleFactor;
        }
    }
    
    int getDisplayAt(int x, int y, CDisplayInfo* info) {
        auto& manager = WindowsDisplayManager::getInstance();
        if (DisplayInfo* display = manager.getDisplayAt(x, y)) {
            strncpy_s(info->id, display->id.c_str(), sizeof(info->id) - 1);
            strncpy_s(info->name, display->name.c_str(), sizeof(info->name) - 1);
            info->x = display->frame.left;
            info->y = display->frame.top;
            info->width = display->frame.right - display->frame.left;
            info->height = display->frame.bottom - display->frame.top;
            info->isPrimary = display->isPrimary ? 1 : 0;
            info->scaleFactor = display->scaleFactor;
            return 1; // Found
        }
        return 0; // Not found
    }
    
    void getTotalScreenBounds(int* x, int* y, int* width, int* height) {
        auto& manager = WindowsDisplayManager::getInstance();
        RECT bounds = manager.getTotalScreenBounds();
        *x = bounds.left;
        *y = bounds.top;
        *width = bounds.right - bounds.left;
        *height = bounds.bottom - bounds.top;
    }
    
    void clampToDisplayBounds(int x, int y, const CDisplayInfo* display, int* clampedX, int* clampedY) {
        *clampedX = max(display->x, min(x, display->x + display->width - 1));
        *clampedY = max(display->y, min(y, display->y + display->height - 1));
    }
}
