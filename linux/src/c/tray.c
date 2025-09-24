#include "tray.h"
#include <stdio.h>

// Minimal no-op tray implementation.
// Future: use GTK StatusIcon/AppIndicator/libayatana-appindicator if available.

int tray_init(const char* app_name) {
    (void)app_name;
    // No-op success so app continues without tray
    return 1;
}

void tray_set_mode(const char* mode_name) {
    (void)mode_name;
}

void tray_set_connected(int connected_clients) {
    (void)connected_clients;
}

void tray_set_active_mouse(const char* mouse_id) {
    (void)mouse_id;
}

void tray_cleanup(void) {}


