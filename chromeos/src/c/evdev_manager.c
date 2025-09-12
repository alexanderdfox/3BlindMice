#include "evdev_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/select.h>
#include <linux/input.h>
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <dirent.h>
#include <sys/stat.h>

// Maximum number of devices
#define MAX_DEVICES 16

// Device structure
typedef struct {
    int fd;
    char path[256];
    uint32_t device_id;
    bool active;
} chromeos_mouse_device_t;

// ChromeOS evdev manager structure
struct chromeos_evdev_manager {
    chromeos_mouse_device_t devices[MAX_DEVICES];
    int device_count;
    chromeos_mouse_input_callback_t callback;
    Display* display;
    bool initialized;
    bool is_crostini;
};

// Global instance for C interface
static chromeos_evdev_manager_t* g_manager = NULL;
static chromeos_mouse_input_callback_t g_callback = NULL;

// Forward declarations
static bool find_chromeos_mouse_devices(chromeos_evdev_manager_t* manager);
static bool open_chromeos_device(chromeos_evdev_manager_t* manager, const char* path);
static void close_chromeos_device(chromeos_mouse_device_t* device);
static void handle_chromeos_device_input(chromeos_evdev_manager_t* manager, int device_index);
static bool is_chromeos_mouse_device(const char* path);
static bool check_crostini_environment(void);

chromeos_evdev_manager_t* chromeos_evdev_manager_create(void) {
    chromeos_evdev_manager_t* manager = calloc(1, sizeof(chromeos_evdev_manager_t));
    if (!manager) {
        fprintf(stderr, "Failed to allocate ChromeOS evdev manager\n");
        return NULL;
    }
    
    // Check if running in Crostini
    manager->is_crostini = check_crostini_environment();
    
    if (manager->is_crostini) {
        manager->display = XOpenDisplay(NULL);
        if (!manager->display) {
            fprintf(stderr, "Failed to open X11 display in Crostini\n");
            free(manager);
            return NULL;
        }
    }
    
    return manager;
}

void chromeos_evdev_manager_destroy(chromeos_evdev_manager_t* manager) {
    if (!manager) return;
    
    // Close all devices
    for (int i = 0; i < manager->device_count; i++) {
        close_chromeos_device(&manager->devices[i]);
    }
    
    // Close X11 display
    if (manager->display) {
        XCloseDisplay(manager->display);
    }
    
    free(manager);
}

bool chromeos_evdev_manager_initialize(chromeos_evdev_manager_t* manager) {
    if (!manager) return false;
    
    if (!manager->is_crostini) {
        fprintf(stderr, "Not running in Crostini environment\n");
        return false;
    }
    
    // Find and open mouse devices
    if (!find_chromeos_mouse_devices(manager)) {
        fprintf(stderr, "Failed to find mouse devices in Crostini\n");
        return false;
    }
    
    if (manager->device_count == 0) {
        fprintf(stderr, "No mouse devices found in Crostini\n");
        return false;
    }
    
    manager->initialized = true;
    printf("✅ Found %d mouse devices in Crostini\n", manager->device_count);
    
    return true;
}

void chromeos_evdev_manager_start_loop(chromeos_evdev_manager_t* manager) {
    if (!manager || !manager->initialized) {
        fprintf(stderr, "ChromeOS evdev manager not initialized\n");
        return;
    }
    
    printf("🎯 Starting ChromeOS event loop...\n");
    
    fd_set read_fds;
    int max_fd = 0;
    
    // Build file descriptor set
    FD_ZERO(&read_fds);
    for (int i = 0; i < manager->device_count; i++) {
        if (manager->devices[i].active) {
            FD_SET(manager->devices[i].fd, &read_fds);
            if (manager->devices[i].fd > max_fd) {
                max_fd = manager->devices[i].fd;
            }
        }
    }
    
    // Event loop
    while (true) {
        fd_set working_fds = read_fds;
        int result = select(max_fd + 1, &working_fds, NULL, NULL, NULL);
        
        if (result < 0) {
            if (errno == EINTR) continue;
            perror("select");
            break;
        }
        
        // Check each device for input
        for (int i = 0; i < manager->device_count; i++) {
            if (manager->devices[i].active && FD_ISSET(manager->devices[i].fd, &working_fds)) {
                handle_chromeos_device_input(manager, i);
            }
        }
    }
}

void chromeos_evdev_manager_set_callback(chromeos_evdev_manager_t* manager, chromeos_mouse_input_callback_t callback) {
    if (manager) {
        manager->callback = callback;
        g_callback = callback;
    }
}

int32_t chromeos_evdev_manager_get_screen_width(void) {
    if (g_manager && g_manager->display) {
        return DisplayWidth(g_manager->display, DefaultScreen(g_manager->display));
    }
    
    // Fallback for ChromeOS
    return 1920; // Default ChromeOS screen width
}

int32_t chromeos_evdev_manager_get_screen_height(void) {
    if (g_manager && g_manager->display) {
        return DisplayHeight(g_manager->display, DefaultScreen(g_manager->display));
    }
    
    // Fallback for ChromeOS
    return 1080; // Default ChromeOS screen height
}

void chromeos_evdev_manager_set_cursor_position(int32_t x, int32_t y) {
    if (g_manager && g_manager->display) {
        XTestFakeMotionEvent(g_manager->display, 0, x, y, CurrentTime);
        XFlush(g_manager->display);
    }
}

bool chromeos_evdev_manager_is_crostini(void) {
    return check_crostini_environment();
}

bool chromeos_evdev_manager_has_permissions(void) {
    // Check if we can access input devices in Crostini
    DIR* dir = opendir("/dev/input");
    if (!dir) return false;
    
    struct dirent* entry;
    bool has_access = false;
    
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "mouse", 5) == 0 || strncmp(entry->d_name, "event", 5) == 0) {
            char path[256];
            snprintf(path, sizeof(path), "/dev/input/%s", entry->d_name);
            
            int fd = open(path, O_RDONLY);
            if (fd >= 0) {
                close(fd);
                has_access = true;
                break;
            }
        }
    }
    
    closedir(dir);
    return has_access;
}

// Helper functions
static bool find_chromeos_mouse_devices(chromeos_evdev_manager_t* manager) {
    DIR* dir = opendir("/dev/input");
    if (!dir) {
        perror("opendir /dev/input");
        return false;
    }
    
    struct dirent* entry;
    int device_count = 0;
    
    while ((entry = readdir(dir)) != NULL && device_count < MAX_DEVICES) {
        if (is_chromeos_mouse_device(entry->d_name)) {
            char path[256];
            snprintf(path, sizeof(path), "/dev/input/%s", entry->d_name);
            
            if (open_chromeos_device(manager, path)) {
                device_count++;
            }
        }
    }
    
    closedir(dir);
    manager->device_count = device_count;
    
    return device_count > 0;
}

static bool open_chromeos_device(chromeos_evdev_manager_t* manager, const char* path) {
    int fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        return false;
    }
    
    int device_index = manager->device_count;
    chromeos_mouse_device_t* device = &manager->devices[device_index];
    
    device->fd = fd;
    strncpy(device->path, path, sizeof(device->path) - 1);
    device->path[sizeof(device->path) - 1] = '\0';
    device->device_id = device_index;
    device->active = true;
    
    printf("✅ Opened ChromeOS device: %s (ID: %u)\n", path, device->device_id);
    
    return true;
}

static void close_chromeos_device(chromeos_mouse_device_t* device) {
    if (device->fd >= 0) {
        close(device->fd);
        device->fd = -1;
        device->active = false;
    }
}

static void handle_chromeos_device_input(chromeos_evdev_manager_t* manager, int device_index) {
    chromeos_mouse_device_t* device = &manager->devices[device_index];
    struct input_event event;
    
    while (read(device->fd, &event, sizeof(event)) == sizeof(event)) {
        if (event.type == EV_REL) {
            int32_t delta_x = 0, delta_y = 0;
            
            if (event.code == REL_X) {
                delta_x = event.value;
            } else if (event.code == REL_Y) {
                delta_y = event.value;
            }
            
            if (delta_x != 0 || delta_y != 0) {
                if (manager->callback) {
                    manager->callback(device->device_id, delta_x, delta_y);
                }
            }
        }
    }
}

static bool is_chromeos_mouse_device(const char* name) {
    return (strncmp(name, "mouse", 5) == 0 || strncmp(name, "event", 5) == 0);
}

static bool check_crostini_environment(void) {
    // Check for Crostini environment indicators
    char* crostini_env = getenv("CROSTINI");
    if (crostini_env && strlen(crostini_env) > 0) {
        return true;
    }
    
    // Check for Crostini-specific files
    if (access("/etc/crostini-release", F_OK) == 0) {
        return true;
    }
    
    // Check for ChromeOS-specific indicators
    if (access("/etc/lsb-release", F_OK) == 0) {
        FILE* file = fopen("/etc/lsb-release", "r");
        if (file) {
            char line[256];
            while (fgets(line, sizeof(line), file)) {
                if (strstr(line, "CHROMEOS_RELEASE_NAME")) {
                    fclose(file);
                    return true;
                }
            }
            fclose(file);
        }
    }
    
    return false;
}

// C interface implementation
void* createChromeOSEvdevManagerNative(void) {
    g_manager = chromeos_evdev_manager_create();
    if (g_manager && chromeos_evdev_manager_initialize(g_manager)) {
        return g_manager;
    }
    return NULL;
}

void startChromeOSEventLoopNative(void) {
    if (g_manager) {
        chromeos_evdev_manager_start_loop(g_manager);
    }
}

int32_t getScreenWidthNative(void) {
    return chromeos_evdev_manager_get_screen_width();
}

int32_t getScreenHeightNative(void) {
    return chromeos_evdev_manager_get_screen_height();
}

void setCursorPositionNative(int32_t x, int32_t y) {
    chromeos_evdev_manager_set_cursor_position(x, y);
}

bool isCrostiniNative(void) {
    return chromeos_evdev_manager_is_crostini();
}

bool hasPermissionsNative(void) {
    return chromeos_evdev_manager_has_permissions();
}
