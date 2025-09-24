 #include <stdio.h>
 #include <stdlib.h>
 #include <stdint.h>
 #include <stdbool.h>
 #include <string.h>
 #include <time.h>
 #include <unistd.h>
 #include <pthread.h>
 #include "evdev_manager.h"
 #include "display_manager.h"
#include "gui.h"
#include "tray.h"
#include "hipaa.h"

 #define MAX_MICE 128

 typedef struct MouseState {
     uint32_t id;
     int32_t pos_x;
     int32_t pos_y;
     int32_t delta_x;
     int32_t delta_y;
     double  weight;
     int64_t last_activity_ms;
     bool    active;
     bool    present;
 } MouseState;

 static MouseState g_mice[MAX_MICE];
 static volatile bool g_use_individual = false;
 static volatile uint32_t g_active_mouse = 0;
 static int32_t g_host_x = 960;
 static int32_t g_host_y = 540;
 static double  g_smoothing = 0.7; // similar to Swift
 static int32_t g_total_w = 1920, g_total_h = 1080, g_total_x = 0, g_total_y = 0;

 static int64_t now_ms(void) {
     struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
     return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
 }

 static MouseState* get_mouse(uint32_t id) {
     for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present && g_mice[i].id == id) return &g_mice[i];
     for (int i = 0; i < MAX_MICE; i++) if (!g_mice[i].present) {
         g_mice[i].present = true;
         g_mice[i].id = id;
         g_mice[i].weight = 1.0;
         g_mice[i].pos_x = g_total_x + g_total_w/2;
         g_mice[i].pos_y = g_total_y + g_total_h/2;
         g_mice[i].delta_x = g_mice[i].delta_y = 0;
         g_mice[i].last_activity_ms = now_ms();
         return &g_mice[i];
     }
     return NULL;
 }

 static void clamp_to_bounds(int32_t* x, int32_t* y) {
     if (*x < g_total_x) *x = g_total_x;
     if (*y < g_total_y) *y = g_total_y;
     if (*x > g_total_x + g_total_w - 1) *x = g_total_x + g_total_w - 1;
     if (*y > g_total_y + g_total_h - 1) *y = g_total_y + g_total_h - 1;
 }

 static void on_mouse_input(uint32_t device_id, int32_t dx, int32_t dy) {
     MouseState* m = get_mouse(device_id);
     if (!m) return;
     m->delta_x += dx;
     m->delta_y += dy;
     m->last_activity_ms = now_ms();
    hipaa_log_input(device_id, dx, dy, m->last_activity_ms);
 }

 static void* keyboard_thread(void* arg) {
     (void)arg;
     while (1) {
         int c = getchar();
         if (c == EOF) { usleep(10000); continue; }
         if (c == 'm' || c == 'M') {
             g_use_individual = !g_use_individual;
             tray_set_mode(g_use_individual ? "Individual" : "Fused");
             printf("🔄 Mode switched to: %s\n", g_use_individual ? "Individual" : "Fused");
         } else if (c == 'i' || c == 'I') {
             printf("📊 Individual positions:\n");
             for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present) {
                 printf("  id=%u pos=(%d,%d) weight=%.2f\n", g_mice[i].id, g_mice[i].pos_x, g_mice[i].pos_y, g_mice[i].weight);
             }
         } else if (c == 'a' || c == 'A') {
             printf("🎯 Active mouse: %u\n", g_active_mouse);
         }
     }
     return NULL;
 }

 static void update_weights(void) {
     const int64_t timeout_ms = 2000;
     int64_t t = now_ms();
     for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present) {
         int64_t dt = t - g_mice[i].last_activity_ms;
         if (dt > timeout_ms) {
             g_mice[i].weight = g_mice[i].weight * 0.9; if (g_mice[i].weight < 0.1) g_mice[i].weight = 0.1;
         } else {
             g_mice[i].weight = g_mice[i].weight * 1.1; if (g_mice[i].weight > 2.0) g_mice[i].weight = 2.0;
         }
     }
 }

 static void apply_deltas_individual(uint32_t id) {
     MouseState* m = get_mouse(id); if (!m) return;
     g_active_mouse = id;
     m->pos_x += m->delta_x; m->pos_y += m->delta_y;
     m->delta_x = m->delta_y = 0;
     clamp_to_bounds(&m->pos_x, &m->pos_y);
     g_host_x = m->pos_x; g_host_y = m->pos_y;
 }

 static void apply_deltas_fused(void) {
     double wx = 0.0, wy = 0.0, tw = 0.0;
     for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present) {
         wx += (double)g_mice[i].delta_x * g_mice[i].weight;
         wy += (double)g_mice[i].delta_y * g_mice[i].weight;
         tw += g_mice[i].weight;
     }
     if (tw > 0.0) {
         double avgx = wx / tw;
         double avgy = wy / tw;
         double new_x = (double)g_host_x + avgx;
         double new_y = (double)g_host_y + avgy;
         g_host_x = (int32_t)((1.0 - g_smoothing) * (double)g_host_x + g_smoothing * new_x);
         g_host_y = (int32_t)((1.0 - g_smoothing) * (double)g_host_y + g_smoothing * new_y);
     }
     for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present) { g_mice[i].delta_x = 0; g_mice[i].delta_y = 0; }
     clamp_to_bounds(&g_host_x, &g_host_y);
 }

 int main(void) {
     printf("\n🐭 3 Blind Mice - Linux (C)\n");
     printf("================================\n");

     if (!evdev_manager_has_permissions()) {
         printf("⚠️  Warning: device permissions may be insufficient.\n");
     }

     display_manager_init();
     display_manager_get_total_screen_bounds(&g_total_x, &g_total_y, &g_total_w, &g_total_h);
     g_host_x = g_total_x + g_total_w/2;
     g_host_y = g_total_y + g_total_h/2;
    if (!gui_init(800, 600, "3 Blind Mice - Linux GUI")) {
        const char* disp = getenv("DISPLAY");
        printf("❌ Failed to open X display.\n");
        printf("   DISPLAY=%s\n", disp ? disp : "(unset)");
        printf("   If running under XFCE, ensure you launch within the desktop session.\n");
        printf("   If using sudo, preserve X credentials, e.g.:\n");
        printf("     sudo -E env DISPLAY=:0 XAUTHORITY=~$SUDO_USER/.Xauthority ./build/bin/ThreeBlindMiceC\n");
        return 1;
    }
    tray_init("3 Blind Mice");
     tray_set_mode("Fused");
    hipaa_init("/var/log/threeblindmice");

     evdev_manager_t* mgr = evdev_manager_create();
     if (!mgr) { printf("❌ Failed to create evdev manager\n"); return 1; }
     if (!evdev_manager_initialize(mgr)) { printf("❌ Failed to initialize evdev manager\n"); return 1; }
     evdev_manager_set_callback(mgr, on_mouse_input);

     pthread_t th; pthread_create(&th, NULL, keyboard_thread, NULL);

     printf("🎯 Event loop active (keys: m=toggle, i=list, a=active, Ctrl+C exit)\n");
     while (1) {
        update_weights(); hipaa_rotate(1024*1024*5, 7);
         if (g_use_individual) {
             // pick most recently active mouse as active
             int64_t latest = -1; uint32_t active = 0;
             for (int i = 0; i < MAX_MICE; i++) if (g_mice[i].present) {
                 if (g_mice[i].last_activity_ms > latest) { latest = g_mice[i].last_activity_ms; active = g_mice[i].id; }
             }
             if (active != 0) {
                 apply_deltas_individual(active);
                 char buf[64]; snprintf(buf, sizeof(buf), "Mouse_%u", active);
                 tray_set_active_mouse(buf);
             }
         } else {
             apply_deltas_fused();
         }
         evdev_manager_set_cursor_position(g_host_x, g_host_y);
         gui_update((double)g_host_x, (double)g_host_y);
         usleep(5000); // ~200 Hz
     }

     // not reached
     return 0;
 }
