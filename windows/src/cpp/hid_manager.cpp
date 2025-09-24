#include "hid_manager.h"
#include <iostream>
#include <memory>

// Global instance for C interface
static std::unique_ptr<WindowsHIDManager> g_hidManager = nullptr;
static std::function<void(UINT32, INT32, INT32)> g_mouseCallback = nullptr;
static std::function<void(UINT32, INT32)> g_scrollCallback = nullptr;

WindowsHIDManager::WindowsHIDManager() : m_hwnd(nullptr), m_initialized(false) {
}

WindowsHIDManager::~WindowsHIDManager() {
    if (m_hwnd) {
        DestroyWindow(m_hwnd);
    }
}

bool WindowsHIDManager::initialize() {
    // Register window class
    WNDCLASSEX wc = {};
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = L"ThreeBlindMiceHIDWindow";
    
    if (!RegisterClassEx(&wc)) {
        std::cerr << "Failed to register window class" << std::endl;
        return false;
    }
    
    // Create hidden window for message processing
    m_hwnd = CreateWindowEx(
        0,
        L"ThreeBlindMiceHIDWindow",
        L"3 Blind Mice HID Window",
        0,
        0, 0, 0, 0,
        HWND_MESSAGE,  // Message-only window
        nullptr,
        GetModuleHandle(nullptr),
        this
    );
    
    if (!m_hwnd) {
        std::cerr << "Failed to create HID window" << std::endl;
        return false;
    }
    
    // Register for raw input
    if (!registerRawInputDevices()) {
        std::cerr << "Failed to register raw input devices" << std::endl;
        return false;
    }
    
    m_initialized = true;
    return true;
}

void WindowsHIDManager::startMessageLoop() {
    if (!m_initialized) {
        std::cerr << "HID Manager not initialized" << std::endl;
        return;
    }
    
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

void WindowsHIDManager::setMouseInputCallback(std::function<void(UINT32, INT32, INT32)> callback) {
    m_mouseCallback = callback;
    g_mouseCallback = callback;
}

void WindowsHIDManager::setScrollInputCallback(std::function<void(UINT32, INT32)> callback) {
    m_scrollCallback = callback;
    g_scrollCallback = callback;
}

INT32 WindowsHIDManager::getScreenWidth() {
    return GetSystemMetrics(SM_CXSCREEN);
}

INT32 WindowsHIDManager::getScreenHeight() {
    return GetSystemMetrics(SM_CYSCREEN);
}

void WindowsHIDManager::setCursorPosition(INT32 x, INT32 y) {
    SetCursorPos(x, y);
}

bool WindowsHIDManager::isRunningAsAdministrator() {
    BOOL isAdmin = FALSE;
    PSID adminGroup = nullptr;
    
    // Create SID for Administrators group
    SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
    if (AllocateAndInitializeSid(&ntAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                                DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &adminGroup)) {
        CheckTokenMembership(nullptr, adminGroup, &isAdmin);
        FreeSid(adminGroup);
    }
    
    return isAdmin == TRUE;
}

LRESULT CALLBACK WindowsHIDManager::WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    WindowsHIDManager* manager = nullptr;
    
    if (uMsg == WM_NCCREATE) {
        CREATESTRUCT* cs = reinterpret_cast<CREATESTRUCT*>(lParam);
        manager = reinterpret_cast<WindowsHIDManager*>(cs->lpCreateParams);
        SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(manager));
    } else {
        manager = reinterpret_cast<WindowsHIDManager*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    }
    
    if (manager) {
        switch (uMsg) {
            case WM_INPUT:
                manager->handleRawInput(lParam);
                break;
            case WM_DESTROY:
                PostQuitMessage(0);
                break;
        }
    }
    
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void WindowsHIDManager::handleRawInput(LPARAM lParam) {
    UINT size = 0;
    GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), RID_INPUT, nullptr, &size, sizeof(RAWINPUTHEADER));
    
    if (size == 0) return;
    
    std::vector<BYTE> buffer(size);
    if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), RID_INPUT, buffer.data(), &size, sizeof(RAWINPUTHEADER)) != size) {
        return;
    }
    
    RAWINPUT* raw = reinterpret_cast<RAWINPUT*>(buffer.data());
    
    if (raw->header.dwType == RIM_TYPEMOUSE) {
        RAWMOUSE& mouse = raw->data.mouse;
        
        // Get device handle for identification
        HANDLE deviceHandle = raw->header.hDevice;
        UINT32 deviceId = reinterpret_cast<UINT32>(deviceHandle);
        
        // Extract mouse movement
        INT32 deltaX = mouse.lLastX;
        INT32 deltaY = mouse.lLastY;
        
        // Extract scroll wheel data
        USHORT wheelDelta = mouse.usButtonData;
        
        // Call the mouse movement callback if set
        if (m_mouseCallback && (deltaX != 0 || deltaY != 0)) {
            m_mouseCallback(deviceId, deltaX, deltaY);
        }
        
        // Call the scroll callback if set and wheel was moved
        if (m_scrollCallback && wheelDelta != 0) {
            m_scrollCallback(deviceId, static_cast<INT32>(wheelDelta));
        }
    }
}

bool WindowsHIDManager::registerRawInputDevices() {
    RAWINPUTDEVICE rid[1];
    
    // Register for mouse input
    rid[0].usUsagePage = HID_USAGE_PAGE_GENERIC;
    rid[0].usUsage = HID_USAGE_GENERIC_MOUSE;
    rid[0].dwFlags = RIDEV_INPUTSINK;
    rid[0].hwndTarget = m_hwnd;
    
    return RegisterRawInputDevices(rid, 1, sizeof(RAWINPUTDEVICE)) == TRUE;
}

// C interface implementation
extern "C" {
    void* createWindowsHIDManagerNative() {
        g_hidManager = std::make_unique<WindowsHIDManager>();
        if (g_hidManager->initialize()) {
            return g_hidManager.get();
        }
        return nullptr;
    }
    
    void startWindowsMessageLoopNative() {
        if (g_hidManager) {
            g_hidManager->startMessageLoop();
        }
    }
    
    INT32 getScreenWidthNative() {
        if (g_hidManager) {
            return g_hidManager->getScreenWidth();
        }
        return GetSystemMetrics(SM_CXSCREEN);
    }
    
    INT32 getScreenHeightNative() {
        if (g_hidManager) {
            return g_hidManager->getScreenHeight();
        }
        return GetSystemMetrics(SM_CYSCREEN);
    }
    
    void setCursorPositionNative(INT32 x, INT32 y) {
        if (g_hidManager) {
            g_hidManager->setCursorPosition(x, y);
        } else {
            SetCursorPos(x, y);
        }
    }
    
    bool isRunningAsAdministratorNative() {
        if (g_hidManager) {
            return g_hidManager->isRunningAsAdministrator();
        }
        
        // Fallback implementation
        BOOL isAdmin = FALSE;
        PSID adminGroup = nullptr;
        
        SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
        if (AllocateAndInitializeSid(&ntAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                                    DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &adminGroup)) {
            CheckTokenMembership(nullptr, adminGroup, &isAdmin);
            FreeSid(adminGroup);
        }
        
        return isAdmin == TRUE;
    }
}
