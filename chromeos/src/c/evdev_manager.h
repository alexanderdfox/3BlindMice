#ifndef CHROMEOS_EVDEV_MANAGER_H
#define CHROMEOS_EVDEV_MANAGER_H

#include <stdint.h>
#include <stdbool.h>

// ChromeOS evdev Manager for multi-mouse support (Crostini)
typedef struct chromeos_evdev_manager chromeos_evdev_manager_t;

// Mouse input callback type
typedef void (*chromeos_mouse_input_callback_t)(uint32_t device_id, int32_t delta_x, int32_t delta_y);

// Create ChromeOS evdev manager
chromeos_evdev_manager_t* chromeos_evdev_manager_create(void);

// Destroy ChromeOS evdev manager
void chromeos_evdev_manager_destroy(chromeos_evdev_manager_t* manager);

// Initialize the ChromeOS evdev manager
bool chromeos_evdev_manager_initialize(chromeos_evdev_manager_t* manager);

// Start the event loop
void chromeos_evdev_manager_start_loop(chromeos_evdev_manager_t* manager);

// Set mouse input callback
void chromeos_evdev_manager_set_callback(chromeos_evdev_manager_t* manager, chromeos_mouse_input_callback_t callback);

// Get screen dimensions (ChromeOS-specific)
int32_t chromeos_evdev_manager_get_screen_width(void);
int32_t chromeos_evdev_manager_get_screen_height(void);

// Set cursor position (ChromeOS-specific)
void chromeos_evdev_manager_set_cursor_position(int32_t x, int32_t y);

// Check if running in Crostini
bool chromeos_evdev_manager_is_crostini(void);

// Check if running with proper permissions
bool chromeos_evdev_manager_has_permissions(void);

// C interface for Swift interop
#ifdef __cplusplus
extern "C" {
#endif

// Create ChromeOS evdev Manager
void* createChromeOSEvdevManagerNative(void);

// Start ChromeOS event loop
void startChromeOSEventLoopNative(void);

// Get screen dimensions
int32_t getScreenWidthNative(void);
int32_t getScreenHeightNative(void);

// Set cursor position
void setCursorPositionNative(int32_t x, int32_t y);

// Check Crostini environment
bool isCrostiniNative(void);

// Check permissions
bool hasPermissionsNative(void);

#ifdef __cplusplus
}
#endif

#endif // CHROMEOS_EVDEV_MANAGER_H
