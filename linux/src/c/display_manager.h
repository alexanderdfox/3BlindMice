#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Display information structure
typedef struct {
    char id[256];
    char name[256];
    int32_t x, y, width, height;
    bool isPrimary;
    float scaleFactor;
} DisplayInfo;

// Display manager functions
void display_manager_init(void);
void display_manager_cleanup(void);
void display_manager_update_displays(void);

// Get display information
int32_t display_manager_get_display_count(void);
void display_manager_get_display_info(int32_t index, DisplayInfo* info);
void display_manager_get_primary_display_info(DisplayInfo* info);
int32_t display_manager_get_display_at(int32_t x, int32_t y, DisplayInfo* info);

// Get total screen bounds
void display_manager_get_total_screen_bounds(int32_t* x, int32_t* y, int32_t* width, int32_t* height);

// Coordinate conversion
void display_manager_clamp_to_display_bounds(int32_t x, int32_t y, const DisplayInfo* display, int32_t* clampedX, int32_t* clampedY);

// Helper functions
const char* display_manager_get_display_name(const DisplayInfo* display);
bool display_manager_is_point_in_display(int32_t x, int32_t y, const DisplayInfo* display);

// GUI bridge (optional)
int gui_init(int width, int height, const char* title);
void gui_update(double host_x, double host_y);
void gui_close(void);

#ifdef __cplusplus
}
#endif

#endif // DISPLAY_MANAGER_H
