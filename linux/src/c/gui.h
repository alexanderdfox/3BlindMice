#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize a simple X11 window. Returns 1 on success, 0 on failure.
int gui_init(int width, int height, const char* title);

// Update the GUI with the current fused cursor position (screen coords 0..1920/1080 scaled to window).
void gui_update(double host_x, double host_y);

// Close the GUI and free resources.
void gui_close(void);

// Optional UI text overlays
void gui_set_mode_text(const char* mode_text);
void gui_set_status_text(const char* status_text);

#ifdef __cplusplus
}
#endif


