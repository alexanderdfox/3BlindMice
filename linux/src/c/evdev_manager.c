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
} mouse_device_t;

// evdev manager structure
struct evdev_manager {
    mouse_device_t devices[MAX_DEVICES];
    int device_count;
    mouse_input_callback_t callback;
    Display* display;
    bool initialized;
};

// Global instance for C interface
static evdev_manager_t* g_manager = NULL;
static mouse_input_callback_t g_callback = NULL;

// Forward declarations
static bool find_mouse_devices(evdev_manager_t* manager);
static bool open_device(evdev_manager_t* manager, const char* path);
static void close_device(mouse_device_t* device);
static void handle_device_input(evdev_manager_t* manager, int device_index);
static bool is_mouse_device(const char* path);

evdev_manager_t* evdev_manager_create(void) {
    evdev_manager_t* manager = calloc(1, sizeof(evdev_manager_t));
    if (!manager) {
        fprintf(stderr, "Failed to allocate evdev manager\n");
        return NULL;
    }
    
    manager->display = XOpenDisplay(NULL);
    if (!manager->display) {
        fprintf(stderr, "Failed to open X11 display\n");
        free(manager);
        return NULL;
    }
    
    return manager;
}

void evdev_manager_destroy(evdev_manager_t* manager) {
    if (!manager) return;
    
    // Close all devices
    for (int i = 0; i < manager->device_count; i++) {
        close_device(&manager->devices[i]);
    }
    
    // Close X11 display
    if (manager->display) {
        XCloseDisplay(manager->display);
    }
    
    free(manager);
}

bool evdev_manager_initialize(evdev_manager_t* manager) {
    if (!manager) return false;
    
    // Find and open mouse devices
    if (!find_mouse_devices(manager)) {
        fprintf(stderr, "Failed to find mouse devices\n");
        return false;
    }
    
    if (manager->device_count == 0) {
        fprintf(stderr, "No mouse devices found\n");
        return false;
    }
    
    manager->initialized = true;
    printf("✅ Found %d mouse devices\n", manager->device_count);
    
    return true;
}

void evdev_manager_start_loop(evdev_manager_t* manager) {
    if (!manager || !manager->initialized) {
        fprintf(stderr, "evdev manager not initialized\n");
        return;
    }
    
    printf("🎯 Starting event loop...\n");
    
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
                handle_device_input(manager, i);
            }
        }
    }
}

void evdev_manager_set_callback(evdev_manager_t* manager, mouse_input_callback_t callback) {
    if (manager) {
        manager->callback = callback;
        g_callback = callback;
    }
}

int32_t evdev_manager_get_screen_width(void) {
    Display* display = XOpenDisplay(NULL);
    if (!display) return 1920; // Default fallback
    
    int32_t width = DisplayWidth(display, DefaultScreen(display));
    XCloseDisplay(display);
    return width;
}

int32_t evdev_manager_get_screen_height(void) {
    Display* display = XOpenDisplay(NULL);
    if (!display) return 1080; // Default fallback
    
    int32_t height = DisplayHeight(display, DefaultScreen(display));
    XCloseDisplay(display);
    return height;
}

void evdev_manager_set_cursor_position(int32_t x, int32_t y) {
    if (g_manager && g_manager->display) {
        XTestFakeMotionEvent(g_manager->display, 0, x, y, CurrentTime);
        XFlush(g_manager->display);
    }
}

bool evdev_manager_has_permissions(void) {
    // Check if we can access input devices
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
static bool find_mouse_devices(evdev_manager_t* manager) {
    DIR* dir = opendir("/dev/input");
    if (!dir) {
        perror("opendir /dev/input");
        return false;
    }
    
    struct dirent* entry;
    int device_count = 0;
    
    while ((entry = readdir(dir)) != NULL && device_count < MAX_DEVICES) {
        if (is_mouse_device(entry->d_name)) {
            char path[256];
            snprintf(path, sizeof(path), "/dev/input/%s", entry->d_name);
            
            if (open_device(manager, path)) {
                device_count++;
            }
        }
    }
    
    closedir(dir);
    manager->device_count = device_count;
    
    return device_count > 0;
}

static bool open_device(evdev_manager_t* manager, const char* path) {
    int fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        return false;
    }
    
    int device_index = manager->device_count;
    mouse_device_t* device = &manager->devices[device_index];
    
    device->fd = fd;
    strncpy(device->path, path, sizeof(device->path) - 1);
    device->path[sizeof(device->path) - 1] = '\0';
    device->device_id = device_index;
    device->active = true;
    
    printf("✅ Opened device: %s (ID: %u)\n", path, device->device_id);
    
    return true;
}

static void close_device(mouse_device_t* device) {
    if (device->fd >= 0) {
        close(device->fd);
        device->fd = -1;
        device->active = false;
    }
}

static void handle_device_input(evdev_manager_t* manager, int device_index) {
    mouse_device_t* device = &manager->devices[device_index];
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

static bool is_mouse_device(const char* name) {
    return (strncmp(name, "mouse", 5) == 0 || strncmp(name, "event", 5) == 0);
}

// C interface implementation
void* createLinuxEvdevManagerNative(void) {
    g_manager = evdev_manager_create();
    if (g_manager && evdev_manager_initialize(g_manager)) {
        return g_manager;
    }
    return NULL;
}

void startLinuxEventLoopNative(void) {
    if (g_manager) {
        evdev_manager_start_loop(g_manager);
    }
}

int32_t getScreenWidthNative(void) {
    return evdev_manager_get_screen_width();
}

int32_t getScreenHeightNative(void) {
    return evdev_manager_get_screen_height();
}

void setCursorPositionNative(int32_t x, int32_t y) {
    evdev_manager_set_cursor_position(x, y);
}

bool hasPermissionsNative(void) {
    return evdev_manager_has_permissions();
}
