#include "gui.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static Display* s_dpy = NULL;
static int s_screen = 0;
static Window s_win = 0;
static GC s_gc = 0;
static int s_w = 800;
static int s_h = 600;
static char s_mode_text[128] = "";
static char s_status_text[256] = "";

int gui_init(int width, int height, const char* title) {
    if (s_dpy) return 1;
    s_dpy = XOpenDisplay(NULL);
    if (!s_dpy) return 0;
    s_screen = DefaultScreen(s_dpy);
    s_w = width > 0 ? width : 800;
    s_h = height > 0 ? height : 600;
    s_win = XCreateSimpleWindow(
        s_dpy,
        RootWindow(s_dpy, s_screen),
        100, 100, (unsigned int)s_w, (unsigned int)s_h, 1,
        BlackPixel(s_dpy, s_screen), WhitePixel(s_dpy, s_screen)
    );
    XStoreName(s_dpy, s_win, title ? title : "3 Blind Mice");
    XSelectInput(s_dpy, s_win, ExposureMask | KeyPressMask | StructureNotifyMask);
    XMapWindow(s_dpy, s_win);
    s_gc = XCreateGC(s_dpy, s_win, 0, NULL);
    XSetForeground(s_dpy, s_gc, BlackPixel(s_dpy, s_screen));
    return 1;
}

static void draw_scene(double host_x, double host_y) {
    if (!s_dpy || !s_win) return;
    XClearWindow(s_dpy, s_win);
    // background gradient-like grid
    XSetForeground(s_dpy, s_gc, 0xEEEEEE);
    int grid = 50;
    for (int x = 0; x <= s_w; x += grid) XDrawLine(s_dpy, s_win, s_gc, x, 0, x, s_h);
    for (int y = 0; y <= s_h; y += grid) XDrawLine(s_dpy, s_win, s_gc, 0, y, s_w, y);

    // draw crosshair at scaled position
    double cx = (host_x / 1920.0) * (double)s_w;
    double cy = (host_y / 1080.0) * (double)s_h;
    int x = (int)(cx + 0.5);
    int y = (int)(cy + 0.5);
    XSetForeground(s_dpy, s_gc, 0x333333);
    XDrawLine(s_dpy, s_win, s_gc, x - 12, y, x + 12, y);
    XDrawLine(s_dpy, s_win, s_gc, x, y - 12, x, y + 12);

    // overlays
    XSetForeground(s_dpy, s_gc, 0x111111);
    if (s_mode_text[0]) XDrawString(s_dpy, s_win, s_gc, 10, 20, s_mode_text, (int)strlen(s_mode_text));
    if (s_status_text[0]) XDrawString(s_dpy, s_win, s_gc, 10, 40, s_status_text, (int)strlen(s_status_text));
    XFlush(s_dpy);
}

void gui_update(double host_x, double host_y) {
    if (!s_dpy) return;
    // handle pending events (resize, expose)
    while (XPending(s_dpy)) {
        XEvent ev; XNextEvent(s_dpy, &ev);
        if (ev.type == ConfigureNotify) {
            XConfigureEvent ce = ev.xconfigure;
            s_w = ce.width;
            s_h = ce.height;
        }
    }
    draw_scene(host_x, host_y);
}

void gui_close(void) {
    if (s_dpy) {
        if (s_gc) { XFreeGC(s_dpy, s_gc); s_gc = 0; }
        if (s_win) { XDestroyWindow(s_dpy, s_win); s_win = 0; }
        XCloseDisplay(s_dpy);
        s_dpy = NULL;
    }
}

void gui_set_mode_text(const char* mode_text) {
    if (!mode_text) { s_mode_text[0] = '\0'; return; }
    snprintf(s_mode_text, sizeof(s_mode_text), "%s", mode_text);
}

void gui_set_status_text(const char* status_text) {
    if (!status_text) { s_status_text[0] = '\0'; return; }
    snprintf(s_status_text, sizeof(s_status_text), "%s", status_text);
}


