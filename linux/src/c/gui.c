#include "gui.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdlib.h>
#include <string.h>

static Display* s_dpy = NULL;
static int s_screen = 0;
static Window s_win = 0;
static GC s_gc = 0;
static int s_w = 800;
static int s_h = 600;

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
    // draw crosshair at scaled position
    double cx = (host_x / 1920.0) * (double)s_w;
    double cy = (host_y / 1080.0) * (double)s_h;
    int x = (int)(cx + 0.5);
    int y = (int)(cy + 0.5);
    XDrawLine(s_dpy, s_win, s_gc, x - 10, y, x + 10, y);
    XDrawLine(s_dpy, s_win, s_gc, x, y - 10, x, y + 10);
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


