#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "evdev_manager.h"
#include "display_manager.h"
#include "gui.h"
#include "tray.h"

static volatile bool g_use_individual = false;
static int32_t g_host_x = 960;
static int32_t g_host_y = 540;

static void on_mouse_input(uint32_t device_id, int32_t dx, int32_t dy) {
    (void)device_id;
    g_host_x += dx;
    g_host_y += dy;
    int32_t x, y, w, h;
    display_manager_get_total_screen_bounds(&x, &y, &w, &h);
    if (g_host_x < x) g_host_x = x;
    if (g_host_y < y) g_host_y = y;
    if (g_host_x > x + w - 1) g_host_x = x + w - 1;
    if (g_host_y > y + h - 1) g_host_y = y + h - 1;
    evdev_manager_set_cursor_position(g_host_x, g_host_y);
    gui_update((double)g_host_x, (double)g_host_y);
}

int main(void) {
    printf("\n🐭 3 Blind Mice - Linux (C)\n");
    printf("================================\n");

    if (!evdev_manager_has_permissions()) {
        printf("⚠️  Warning: device permissions may be insufficient.\n");
    }

    display_manager_init();
    int32_t sx=0, sy=0, sw=1920, sh=1080;
    display_manager_get_total_screen_bounds(&sx, &sy, &sw, &sh);
    g_host_x = sx + sw/2;
    g_host_y = sy + sh/2;
    gui_init(800, 600, "3 Blind Mice - Linux GUI");
    tray_init("3 Blind Mice");

    evdev_manager_t* mgr = evdev_manager_create();
    if (!mgr) { printf("❌ Failed to create evdev manager\n"); return 1; }
    if (!evdev_manager_initialize(mgr)) { printf("❌ Failed to initialize evdev manager\n"); return 1; }
    evdev_manager_set_callback(mgr, on_mouse_input);

    printf("🎯 Starting event loop (Ctrl+C to exit)\n");
    evdev_manager_start_loop(mgr);

    tray_cleanup();
    gui_close();
    display_manager_cleanup();
    evdev_manager_destroy(mgr);
    return 0;
}
