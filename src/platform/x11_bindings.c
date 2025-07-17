#include "x11_bindings.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <GL/glx.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Atom wm_delete_window = 0;

Display* jaguar_x11_open_display(const char* display_name) {
    Display* display = XOpenDisplay(display_name);
    if (display) {
        wm_delete_window = XInternAtom(display, "WM_DELETE_WINDOW", False);
    }
    return display;
}

void jaguar_x11_close_display(Display* display) {
    if (display) {
        XCloseDisplay(display);
    }
}

Window jaguar_x11_create_window(Display* display, int width, int height, const char* title) {
    if (!display) return 0;
    
    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);
    
    // Choose visual for OpenGL
    int visual_attribs[] = {
        GLX_X_RENDERABLE, True,
        GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
        GLX_RENDER_TYPE, GLX_RGBA_BIT,
        GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR,
        GLX_RED_SIZE, 8,
        GLX_GREEN_SIZE, 8,
        GLX_BLUE_SIZE, 8,
        GLX_ALPHA_SIZE, 8,
        GLX_DEPTH_SIZE, 24,
        GLX_STENCIL_SIZE, 8,
        GLX_DOUBLEBUFFER, True,
        None
    };
    
    int fbcount;
    GLXFBConfig* fbc = glXChooseFBConfig(display, screen, visual_attribs, &fbcount);
    if (!fbc) {
        fprintf(stderr, "Failed to retrieve framebuffer config\n");
        return 0;
    }
    
    GLXFBConfig bestFbc = fbc[0];
    XFree(fbc);
    
    XVisualInfo* vi = glXGetVisualFromFBConfig(display, bestFbc);
    if (!vi) {
        fprintf(stderr, "Failed to get visual info\n");
        return 0;
    }
    
    Colormap cmap = XCreateColormap(display, root, vi->visual, AllocNone);
    
    XSetWindowAttributes swa;
    swa.colormap = cmap;
    swa.background_pixmap = None;
    swa.border_pixel = 0;
    swa.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask | 
                     ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
                     StructureNotifyMask;
    
    Window window = XCreateWindow(display, root, 0, 0, width, height, 0,
                                  vi->depth, InputOutput, vi->visual,
                                  CWBorderPixel | CWColormap | CWEventMask, &swa);
    
    XFree(vi);
    
    if (!window) {
        XFreeColormap(display, cmap);
        return 0;
    }
    
    // Set window title
    XStoreName(display, window, title);
    
    // Set up window manager delete protocol
    XSetWMProtocols(display, window, &wm_delete_window, 1);
    
    // Map window
    XMapWindow(display, window);
    
    return window;
}

void jaguar_x11_destroy_window(Display* display, Window window) {
    if (display && window) {
        XDestroyWindow(display, window);
    }
}

bool jaguar_x11_poll_event(Display* display, XEvent* event) {
    if (!display) return false;
    
    if (XPending(display) > 0) {
        XNextEvent(display, event);
        return true;
    }
    return false;
}

void jaguar_x11_swap_buffers(Display* display, GLXDrawable drawable) {
    if (display && drawable) {
        glXSwapBuffers(display, drawable);
    }
}

bool jaguar_x11_should_close(Display* display, Window window) {
    // This is handled through events in the poll_event function
    (void)display;
    (void)window;
    return false;
}

void jaguar_x11_get_window_size(Display* display, Window window, int* width, int* height) {
    if (!display || !window || !width || !height) return;
    
    XWindowAttributes attrs;
    if (XGetWindowAttributes(display, window, &attrs) == 0) {
        *width = 800;
        *height = 600;
        return;
    }
    
    *width = attrs.width;
    *height = attrs.height;
}

GLXContext jaguar_x11_create_gl_context(Display* display, Window window) {
    if (!display || !window) return NULL;
    
    int screen = DefaultScreen(display);
    
    int visual_attribs[] = {
        GLX_X_RENDERABLE, True,
        GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
        GLX_RENDER_TYPE, GLX_RGBA_BIT,
        GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR,
        GLX_RED_SIZE, 8,
        GLX_GREEN_SIZE, 8,
        GLX_BLUE_SIZE, 8,
        GLX_ALPHA_SIZE, 8,
        GLX_DEPTH_SIZE, 24,
        GLX_STENCIL_SIZE, 8,
        GLX_DOUBLEBUFFER, True,
        None
    };
    
    int fbcount;
    GLXFBConfig* fbc = glXChooseFBConfig(display, screen, visual_attribs, &fbcount);
    if (!fbc) return NULL;
    
    GLXFBConfig bestFbc = fbc[0];
    XFree(fbc);
    
    // Create OpenGL context
    GLXContext context = glXCreateNewContext(display, bestFbc, GLX_RGBA_TYPE, NULL, True);
    return context;
}

void jaguar_x11_make_current(Display* display, GLXDrawable drawable, GLXContext context) {
    if (display && drawable && context) {
        glXMakeContextCurrent(display, drawable, drawable, context);
    }
}

void jaguar_x11_destroy_gl_context(Display* display, GLXContext context) {
    if (display && context) {
        glXDestroyContext(display, context);
    }
}
