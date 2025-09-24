#include "display_manager.h"
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global display manager state
static Display* g_display = NULL;
static DisplayInfo* g_displays = NULL;
static int32_t g_display_count = 0;
static DisplayInfo* g_primary_display = NULL;

// Forward declarations
static void enumerate_outputs(void);
static void cleanup_displays(void);
static const char* get_output_name(RROutput output);
static float get_output_scale_factor(RROutput output);

void display_manager_init(void) {
    g_display = XOpenDisplay(NULL);
    if (!g_display) {
        printf("❌ Failed to open X display\n");
        return;
    }
    
    // Check for XRandR extension
    int event_base, error_base;
    if (!XRRQueryExtension(g_display, &event_base, &error_base)) {
        printf("❌ XRandR extension not available\n");
        return;
    }
    
    display_manager_update_displays();
}

void display_manager_cleanup(void) {
    cleanup_displays();
    
    if (g_display) {
        XCloseDisplay(g_display);
        g_display = NULL;
    }
}

void display_manager_update_displays(void) {
    if (!g_display) {
        printf("❌ Display not initialized\n");
        return;
    }
    
    cleanup_displays();
    enumerate_outputs();
    
    printf("🖥️  Updated displays: %d found\n", g_display_count);
    for (int32_t i = 0; i < g_display_count; ++i) {
        const DisplayInfo* display = &g_displays[i];
        printf("   Display %d: %s (%dx%d) %s\n", 
               i + 1, display->name, display->width, display->height,
               display->isPrimary ? "[PRIMARY]" : "");
    }
}

int32_t display_manager_get_display_count(void) {
    return g_display_count;
}

void display_manager_get_display_info(int32_t index, DisplayInfo* info) {
    if (!info || index < 0 || index >= g_display_count) {
        return;
    }
    
    *info = g_displays[index];
}

void display_manager_get_primary_display_info(DisplayInfo* info) {
    if (!info || !g_primary_display) {
        return;
    }
    
    *info = *g_primary_display;
}

int32_t display_manager_get_display_at(int32_t x, int32_t y, DisplayInfo* info) {
    if (!info) {
        return 0;
    }
    
    for (int32_t i = 0; i < g_display_count; ++i) {
        const DisplayInfo* display = &g_displays[i];
        if (display_manager_is_point_in_display(x, y, display)) {
            *info = *display;
            return 1; // Found
        }
    }
    
    return 0; // Not found
}

void display_manager_get_total_screen_bounds(int32_t* x, int32_t* y, int32_t* width, int32_t* height) {
    if (!x || !y || !width || !height || g_display_count == 0) {
        *x = *y = 0;
        *width = 1920;
        *height = 1080;
        return;
    }
    
    int32_t minX = g_displays[0].x;
    int32_t minY = g_displays[0].y;
    int32_t maxX = g_displays[0].x + g_displays[0].width;
    int32_t maxY = g_displays[0].y + g_displays[0].height;
    
    for (int32_t i = 1; i < g_display_count; ++i) {
        const DisplayInfo* display = &g_displays[i];
        minX = (display->x < minX) ? display->x : minX;
        minY = (display->y < minY) ? display->y : minY;
        maxX = (display->x + display->width > maxX) ? display->x + display->width : maxX;
        maxY = (display->y + display->height > maxY) ? display->y + display->height : maxY;
    }
    
    *x = minX;
    *y = minY;
    *width = maxX - minX;
    *height = maxY - minY;
}

void display_manager_clamp_to_display_bounds(int32_t x, int32_t y, const DisplayInfo* display, int32_t* clampedX, int32_t* clampedY) {
    if (!display || !clampedX || !clampedY) {
        return;
    }
    
    *clampedX = (x < display->x) ? display->x : 
                (x >= display->x + display->width) ? display->x + display->width - 1 : x;
    *clampedY = (y < display->y) ? display->y : 
                (y >= display->y + display->height) ? display->y + display->height - 1 : y;
}

const char* display_manager_get_display_name(const DisplayInfo* display) {
    return display ? display->name : "Unknown";
}

bool display_manager_is_point_in_display(int32_t x, int32_t y, const DisplayInfo* display) {
    if (!display) {
        return false;
    }
    
    return (x >= display->x && x < display->x + display->width &&
            y >= display->y && y < display->y + display->height);
}

// Private functions
static void enumerate_outputs(void) {
    if (!g_display) {
        return;
    }
    
    Window root = DefaultRootWindow(g_display);
    XRRScreenResources* screen_resources = XRRGetScreenResources(g_display, root);
    
    if (!screen_resources) {
        printf("❌ Failed to get screen resources\n");
        return;
    }
    
    // Count connected outputs
    int32_t connected_count = 0;
    for (int i = 0; i < screen_resources->noutput; ++i) {
        XRROutputInfo* output_info = XRRGetOutputInfo(g_display, screen_resources, screen_resources->outputs[i]);
        if (output_info && output_info->connection == RR_Connected) {
            connected_count++;
        }
        if (output_info) {
            XRRFreeOutputInfo(output_info);
        }
    }
    
    if (connected_count == 0) {
        printf("❌ No connected outputs found\n");
        XRRFreeScreenResources(screen_resources);
        return;
    }
    
    // Allocate display array
    g_displays = (DisplayInfo*)calloc(connected_count, sizeof(DisplayInfo));
    if (!g_displays) {
        printf("❌ Failed to allocate display array\n");
        XRRFreeScreenResources(screen_resources);
        return;
    }
    
    // Enumerate connected outputs
    int32_t display_index = 0;
    for (int i = 0; i < screen_resources->noutput; ++i) {
        XRROutputInfo* output_info = XRRGetOutputInfo(g_display, screen_resources, screen_resources->outputs[i]);
        
        if (output_info && output_info->connection == RR_Connected) {
            DisplayInfo* display = &g_displays[display_index];
            
            // Get output name
            const char* name = get_output_name(screen_resources->outputs[i]);
            strncpy(display->name, name, sizeof(display->name) - 1);
            display->name[sizeof(display->name) - 1] = '\0';
            
            // Generate ID
            snprintf(display->id, sizeof(display->id), "output_%lu", screen_resources->outputs[i]);
            
            // Get current mode
            if (output_info->nmode > 0) {
                XRRModeInfo* mode_info = NULL;
                for (int j = 0; j < screen_resources->nmode; ++j) {
                    if (screen_resources->modes[j].id == output_info->modes[output_info->npreferred]) {
                        mode_info = &screen_resources->modes[j];
                        break;
                    }
                }
                
                if (mode_info) {
                    display->width = mode_info->width;
                    display->height = mode_info->height;
                } else {
                    display->width = 1920;
                    display->height = 1080;
                }
            } else {
                display->width = 1920;
                display->height = 1080;
            }
            
            // Get position (simplified - assume primary at 0,0)
            display->x = (display_index == 0) ? 0 : display_index * display->width;
            display->y = 0;
            
            // Check if primary
            display->isPrimary = (display_index == 0);
            
            // Get scale factor
            display->scaleFactor = get_output_scale_factor(screen_resources->outputs[i]);
            
            if (display->isPrimary) {
                g_primary_display = display;
            }
            
            display_index++;
        }
        
        if (output_info) {
            XRRFreeOutputInfo(output_info);
        }
    }
    
    g_display_count = display_index;
    XRRFreeScreenResources(screen_resources);
}

static void cleanup_displays(void) {
    if (g_displays) {
        free(g_displays);
        g_displays = NULL;
    }
    g_display_count = 0;
    g_primary_display = NULL;
}

static const char* get_output_name(RROutput output) {
    static char name_buffer[256];
    name_buffer[0] = '\0';
    
    if (!g_display) {
        return "Unknown";
    }
    
    Window root = DefaultRootWindow(g_display);
    XRRScreenResources* resources = NULL;
    
    // Prefer Current if available; fallback to GetScreenResources
#ifdef XrandrServer
    resources = XRRGetScreenResourcesCurrent(g_display, root);
#else
    resources = XRRGetScreenResources(g_display, root);
#endif
    if (!resources) {
        return "Unknown";
    }
    
    XRROutputInfo* output_info = XRRGetOutputInfo(g_display, resources, output);
    if (!output_info) {
        XRRFreeScreenResources(resources);
        return "Unknown";
    }
    
    if (output_info->name && output_info->name[0] != '\0') {
        strncpy(name_buffer, output_info->name, sizeof(name_buffer) - 1);
        name_buffer[sizeof(name_buffer) - 1] = '\0';
    } else {
        strncpy(name_buffer, "Unknown", sizeof(name_buffer) - 1);
        name_buffer[sizeof(name_buffer) - 1] = '\0';
    }
    
    XRRFreeOutputInfo(output_info);
    XRRFreeScreenResources(resources);
    
    return name_buffer[0] ? name_buffer : "Unknown";
}

static float get_output_scale_factor(RROutput output) {
    // Simplified scale factor detection
    // In a real implementation, you'd query the actual DPI/scale settings
    return 1.0f;
}

// C-friendly getters for Swift bridge
void dm_get_display_info_c(int32_t index,
                           char* idOut, int idOutSize,
                           char* nameOut, int nameOutSize,
                           int32_t* xOut, int32_t* yOut,
                           int32_t* wOut, int32_t* hOut,
                           bool* isPrimaryOut, float* scaleOut) {
    if (index < 0 || index >= g_display_count) return;
    const DisplayInfo* d = &g_displays[index];
    if (idOut && idOutSize > 0) { snprintf(idOut, idOutSize, "%s", d->id); }
    if (nameOut && nameOutSize > 0) { snprintf(nameOut, nameOutSize, "%s", d->name); }
    if (xOut) *xOut = d->x;
    if (yOut) *yOut = d->y;
    if (wOut) *wOut = d->width;
    if (hOut) *hOut = d->height;
    if (isPrimaryOut) *isPrimaryOut = d->isPrimary;
    if (scaleOut) *scaleOut = d->scaleFactor;
}

void dm_get_primary_info_c(char* idOut, int idOutSize,
                           char* nameOut, int nameOutSize,
                           int32_t* xOut, int32_t* yOut,
                           int32_t* wOut, int32_t* hOut,
                           bool* isPrimaryOut, float* scaleOut) {
    if (!g_primary_display) return;
    const DisplayInfo* d = g_primary_display;
    if (idOut && idOutSize > 0) { snprintf(idOut, idOutSize, "%s", d->id); }
    if (nameOut && nameOutSize > 0) { snprintf(nameOut, nameOutSize, "%s", d->name); }
    if (xOut) *xOut = d->x;
    if (yOut) *yOut = d->y;
    if (wOut) *wOut = d->width;
    if (hOut) *hOut = d->height;
    if (isPrimaryOut) *isPrimaryOut = d->isPrimary;
    if (scaleOut) *scaleOut = d->scaleFactor;
}

int dm_get_display_at_c(int32_t x, int32_t y,
                        char* idOut, int idOutSize,
                        char* nameOut, int nameOutSize,
                        int32_t* xOut, int32_t* yOut,
                        int32_t* wOut, int32_t* hOut,
                        bool* isPrimaryOut, float* scaleOut) {
    DisplayInfo info;
    if (display_manager_get_display_at(x, y, &info)) {
        if (idOut && idOutSize > 0) { snprintf(idOut, idOutSize, "%s", info.id); }
        if (nameOut && nameOutSize > 0) { snprintf(nameOut, nameOutSize, "%s", info.name); }
        if (xOut) *xOut = info.x;
        if (yOut) *yOut = info.y;
        if (wOut) *wOut = info.width;
        if (hOut) *hOut = info.height;
        if (isPrimaryOut) *isPrimaryOut = info.isPrimary;
        if (scaleOut) *scaleOut = info.scaleFactor;
        return 1;
    }
    return 0;
}
