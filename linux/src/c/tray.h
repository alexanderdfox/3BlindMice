#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize system tray (no-op if GTK/AppIndicator unavailable)
// Returns 1 on success (or treated-as-success in no-op), 0 on hard failure
int tray_init(const char* app_name);

// Update menu/status info
void tray_set_mode(const char* mode_name);
void tray_set_connected(int connected_clients);
void tray_set_active_mouse(const char* mouse_id);

// Cleanup tray resources
void tray_cleanup(void);

#ifdef __cplusplus
}
#endif


