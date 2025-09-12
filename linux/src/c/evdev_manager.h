#ifndef EVDEV_MANAGER_H
#define EVDEV_MANAGER_H

#include <stdint.h>
#include <stdbool.h>

// Linux evdev Manager for multi-mouse support
typedef struct evdev_manager evdev_manager_t;

// Mouse input callback type
typedef void (*mouse_input_callback_t)(uint32_t device_id, int32_t delta_x, int32_t delta_y);

// Create evdev manager
evdev_manager_t* evdev_manager_create(void);

// Destroy evdev manager
void evdev_manager_destroy(evdev_manager_t* manager);

// Initialize the evdev manager
bool evdev_manager_initialize(evdev_manager_t* manager);

// Start the event loop
void evdev_manager_start_loop(evdev_manager_t* manager);

// Set mouse input callback
void evdev_manager_set_callback(evdev_manager_t* manager, mouse_input_callback_t callback);

// Get screen dimensions
int32_t evdev_manager_get_screen_width(void);
int32_t evdev_manager_get_screen_height(void);

// Set cursor position
void evdev_manager_set_cursor_position(int32_t x, int32_t y);

// Check if running with proper permissions
bool evdev_manager_has_permissions(void);

// C interface for Swift interop
#ifdef __cplusplus
extern "C" {
#endif

// Create Linux evdev Manager
void* createLinuxEvdevManagerNative(void);

// Start Linux event loop
void startLinuxEventLoopNative(void);

// Get screen dimensions
int32_t getScreenWidthNative(void);
int32_t getScreenHeightNative(void);

// Set cursor position
void setCursorPositionNative(int32_t x, int32_t y);

// Check permissions
bool hasPermissionsNative(void);

#ifdef __cplusplus
}
#endif

#endif // EVDEV_MANAGER_H
