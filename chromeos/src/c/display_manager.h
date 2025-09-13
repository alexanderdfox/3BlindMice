#ifndef CHROMEOS_DISPLAY_MANAGER_H
#define CHROMEOS_DISPLAY_MANAGER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Display information structure for ChromeOS
typedef struct {
    char id[256];
    char name[256];
    int32_t x, y, width, height;
    bool isPrimary;
    float scaleFactor;
} ChromeOSDisplayInfo;

// ChromeOS display manager functions
void chromeos_display_manager_init(void);
void chromeos_display_manager_cleanup(void);
void chromeos_display_manager_update_displays(void);

// Get display information
int32_t chromeos_display_manager_get_display_count(void);
void chromeos_display_manager_get_display_info(int32_t index, ChromeOSDisplayInfo* info);
void chromeos_display_manager_get_primary_display_info(ChromeOSDisplayInfo* info);
int32_t chromeos_display_manager_get_display_at(int32_t x, int32_t y, ChromeOSDisplayInfo* info);

// Get total screen bounds
void chromeos_display_manager_get_total_screen_bounds(int32_t* x, int32_t* y, int32_t* width, int32_t* height);

// Coordinate conversion
void chromeos_display_manager_clamp_to_display_bounds(int32_t x, int32_t y, const ChromeOSDisplayInfo* display, int32_t* clampedX, int32_t* clampedY);

// ChromeOS-specific functions
bool chromeos_display_manager_is_crostini_available(void);
void chromeos_display_manager_setup_crostini_displays(void);

#ifdef __cplusplus
}
#endif

#endif // CHROMEOS_DISPLAY_MANAGER_H
