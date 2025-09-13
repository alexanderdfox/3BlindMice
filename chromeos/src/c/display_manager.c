#include "display_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// ChromeOS display manager state
static ChromeOSDisplayInfo* g_displays = NULL;
static int32_t g_display_count = 0;
static ChromeOSDisplayInfo* g_primary_display = NULL;
static bool g_crostini_available = false;

// Forward declarations
static void detect_crostini_environment(void);
static void setup_chromeos_displays(void);
static void cleanup_displays(void);
static bool is_chromeos_system(void);

void chromeos_display_manager_init(void) {
    detect_crostini_environment();
    chromeos_display_manager_update_displays();
}

void chromeos_display_manager_cleanup(void) {
    cleanup_displays();
}

void chromeos_display_manager_update_displays(void) {
    cleanup_displays();
    setup_chromeos_displays();
    
    printf("🖥️  Updated ChromeOS displays: %d found\n", g_display_count);
    for (int32_t i = 0; i < g_display_count; ++i) {
        const ChromeOSDisplayInfo* display = &g_displays[i];
        printf("   Display %d: %s (%dx%d) %s\n", 
               i + 1, display->name, display->width, display->height,
               display->isPrimary ? "[PRIMARY]" : "");
    }
}

int32_t chromeos_display_manager_get_display_count(void) {
    return g_display_count;
}

void chromeos_display_manager_get_display_info(int32_t index, ChromeOSDisplayInfo* info) {
    if (!info || index < 0 || index >= g_display_count) {
        return;
    }
    
    *info = g_displays[index];
}

void chromeos_display_manager_get_primary_display_info(ChromeOSDisplayInfo* info) {
    if (!info || !g_primary_display) {
        return;
    }
    
    *info = *g_primary_display;
}

int32_t chromeos_display_manager_get_display_at(int32_t x, int32_t y, ChromeOSDisplayInfo* info) {
    if (!info) {
        return 0;
    }
    
    for (int32_t i = 0; i < g_display_count; ++i) {
        const ChromeOSDisplayInfo* display = &g_displays[i];
        if (x >= display->x && x < display->x + display->width &&
            y >= display->y && y < display->y + display->height) {
            *info = *display;
            return 1; // Found
        }
    }
    
    return 0; // Not found
}

void chromeos_display_manager_get_total_screen_bounds(int32_t* x, int32_t* y, int32_t* width, int32_t* height) {
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
        const ChromeOSDisplayInfo* display = &g_displays[i];
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

void chromeos_display_manager_clamp_to_display_bounds(int32_t x, int32_t y, const ChromeOSDisplayInfo* display, int32_t* clampedX, int32_t* clampedY) {
    if (!display || !clampedX || !clampedY) {
        return;
    }
    
    *clampedX = (x < display->x) ? display->x : 
                (x >= display->x + display->width) ? display->x + display->width - 1 : x;
    *clampedY = (y < display->y) ? display->y : 
                (y >= display->y + display->height) ? display->y + display->height - 1 : y;
}

bool chromeos_display_manager_is_crostini_available(void) {
    return g_crostini_available;
}

void chromeos_display_manager_setup_crostini_displays(void) {
    if (g_crostini_available) {
        // In Crostini, we can use X11/XRandR similar to Linux
        // For now, we'll use a simplified approach
        printf("🖥️  Setting up Crostini displays\n");
    }
}

// Private functions
static void detect_crostini_environment(void) {
    // Check if we're running in Crostini
    g_crostini_available = false;
    
    // Check for Crostini-specific environment variables
    if (getenv("CROSTINI") || getenv("CHROMEOS_DEV_CONTAINER")) {
        g_crostini_available = true;
        printf("🖥️  Detected Crostini environment\n");
        return;
    }
    
    // Check for ChromeOS-specific files
    if (access("/etc/cros_chrome_build", F_OK) == 0) {
        g_crostini_available = true;
        printf("🖥️  Detected ChromeOS environment\n");
        return;
    }
    
    // Check if we're in a Chrome extension context
    if (getenv("CHROME_EXTENSION")) {
        g_crostini_available = false;
        printf("🖥️  Running in Chrome extension context\n");
        return;
    }
    
    printf("🖥️  Running in unknown ChromeOS context\n");
}

static void setup_chromeos_displays(void) {
    if (g_crostini_available) {
        // In Crostini, we can detect multiple displays using X11
        // For now, create a default display
        g_display_count = 1;
        g_displays = (ChromeOSDisplayInfo*)calloc(1, sizeof(ChromeOSDisplayInfo));
        
        if (g_displays) {
            ChromeOSDisplayInfo* display = &g_displays[0];
            strcpy(display->id, "crostini_primary");
            strcpy(display->name, "Crostini Display");
            display->x = 0;
            display->y = 0;
            display->width = 1920;
            display->height = 1080;
            display->isPrimary = true;
            display->scaleFactor = 1.0f;
            
            g_primary_display = display;
        }
    } else {
        // In Chrome extension context, we'll use the browser's display info
        // For now, create a default display
        g_display_count = 1;
        g_displays = (ChromeOSDisplayInfo*)calloc(1, sizeof(ChromeOSDisplayInfo));
        
        if (g_displays) {
            ChromeOSDisplayInfo* display = &g_displays[0];
            strcpy(display->id, "chrome_primary");
            strcpy(display->name, "Chrome Display");
            display->x = 0;
            display->y = 0;
            display->width = 1920;
            display->height = 1080;
            display->isPrimary = true;
            display->scaleFactor = 1.0f;
            
            g_primary_display = display;
        }
    }
}

static void cleanup_displays(void) {
    if (g_displays) {
        free(g_displays);
        g_displays = NULL;
    }
    g_display_count = 0;
    g_primary_display = NULL;
}

static bool is_chromeos_system(void) {
    // Check for ChromeOS-specific indicators
    return (access("/etc/cros_chrome_build", F_OK) == 0) ||
           (getenv("CROSTINI") != NULL) ||
           (getenv("CHROMEOS_DEV_CONTAINER") != NULL);
}
