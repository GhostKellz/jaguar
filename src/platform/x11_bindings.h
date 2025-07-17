// Minimal X11 bindings for basic windowing
#ifndef JAGUAR_X11_H
#define JAGUAR_X11_H

#include <stdint.h>
#include <stdbool.h>

// Basic X11 types
typedef struct _XDisplay Display;
typedef unsigned long Window;
typedef unsigned long Atom;
typedef struct {
    int type;
    unsigned long serial;
    bool send_event;
    Display *display;
    Window window;
    Window root;
    Window subwindow;
    unsigned long time;
    int x, y;
    int x_root, y_root;
    unsigned int state;
    unsigned int keycode;
    bool same_screen;
} XKeyEvent;

typedef struct {
    int type;
    unsigned long serial;
    bool send_event;
    Display *display;
    Window window;
    Window root;
    Window subwindow;
    unsigned long time;
    int x, y;
    int x_root, y_root;
    unsigned int state;
    unsigned int button;
    bool same_screen;
} XButtonEvent;

typedef struct {
    int type;
    unsigned long serial;
    bool send_event;
    Display *display;
    Window window;
    int x, y;
    int width, height;
    int border_width;
    Window above;
    bool override_redirect;
} XConfigureEvent;

typedef union {
    int type;
    XKeyEvent xkey;
    XButtonEvent xbutton;
    XConfigureEvent xconfigure;
    char pad[24];
} XEvent;

// OpenGL context types
typedef struct __GLXcontextRec *GLXContext;
typedef unsigned long GLXDrawable;

// Function declarations
Display* jaguar_x11_open_display(const char* display_name);
void jaguar_x11_close_display(Display* display);
Window jaguar_x11_create_window(Display* display, int width, int height, const char* title);
void jaguar_x11_destroy_window(Display* display, Window window);
bool jaguar_x11_poll_event(Display* display, XEvent* event);
void jaguar_x11_swap_buffers(Display* display, GLXDrawable drawable);
bool jaguar_x11_should_close(Display* display, Window window);
void jaguar_x11_get_window_size(Display* display, Window window, int* width, int* height);

// OpenGL context functions
GLXContext jaguar_x11_create_gl_context(Display* display, Window window);
void jaguar_x11_make_current(Display* display, GLXDrawable drawable, GLXContext context);
void jaguar_x11_destroy_gl_context(Display* display, GLXContext context);

#endif // JAGUAR_X11_H
