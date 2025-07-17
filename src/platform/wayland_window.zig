const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const wayland = @import("wayland.zig");
const Event = @import("../events/event.zig");
const WindowConfig = @import("window.zig").WindowConfig;

/// Wayland-based window implementation for Linux
pub const WaylandWindow = struct {
    allocator: Allocator,
    display: ?*wayland.wl_display,
    registry: ?*wayland.wl_registry,
    compositor: ?*wayland.wl_compositor,
    xdg_wm_base: ?*wayland.xdg_wm_base,
    seat: ?*wayland.wl_seat,
    pointer: ?*wayland.wl_pointer,
    keyboard: ?*wayland.wl_keyboard,
    surface: ?*wayland.wl_surface,
    xdg_surface: ?*wayland.xdg_surface,
    xdg_toplevel: ?*wayland.xdg_toplevel,

    // EGL context for OpenGL
    egl_display: wayland.EGLDisplay,
    egl_surface: wayland.EGLSurface,
    egl_context: wayland.EGLContext,

    // Window state
    width: u32,
    height: u32,
    should_close: bool,
    configured: bool,

    // Mouse state
    last_mouse_x: f64,
    last_mouse_y: f64,
    first_mouse: bool,

    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !Self {
        var window = Self{
            .allocator = allocator,
            .display = null,
            .registry = null,
            .compositor = null,
            .xdg_wm_base = null,
            .seat = null,
            .pointer = null,
            .keyboard = null,
            .surface = null,
            .xdg_surface = null,
            .xdg_toplevel = null,
            .egl_display = null,
            .egl_surface = null,
            .egl_context = null,
            .width = config.width,
            .height = config.height,
            .should_close = false,
            .configured = false,
            .last_mouse_x = 0,
            .last_mouse_y = 0,
            .first_mouse = true,
        };

        try window.initWayland(config);
        try window.initEGL();

        return window;
    }

    fn initWayland(self: *Self, config: WindowConfig) !void {
        // Connect to Wayland display
        self.display = wayland.wl_display_connect(null);
        if (self.display == null) {
            return error.WaylandDisplayConnect;
        }

        // Get registry
        self.registry = wayland.wl_display_get_registry(self.display);
        if (self.registry == null) {
            return error.WaylandGetRegistry;
        }

        // Set up registry listener
        const registry_listener = wayland.wl_registry_listener{
            .global = registryHandleGlobal,
            .global_remove = registryHandleGlobalRemove,
        };

        _ = wayland.wl_registry_add_listener(self.registry, &registry_listener, self);

        // Wait for globals
        _ = wayland.wl_display_roundtrip(self.display);

        if (self.compositor == null or self.xdg_wm_base == null) {
            return error.WaylandMissingGlobals;
        }

        // Create surface
        self.surface = wayland.wl_compositor_create_surface(self.compositor);
        if (self.surface == null) {
            return error.WaylandCreateSurface;
        }

        // Set up XDG WM Base listener
        const xdg_wm_base_listener = wayland.xdg_wm_base_listener{
            .ping = xdgWmBasePing,
        };
        _ = wayland.xdg_wm_base_add_listener(self.xdg_wm_base, &xdg_wm_base_listener, self);

        // Create XDG surface
        self.xdg_surface = wayland.xdg_wm_base_get_xdg_surface(self.xdg_wm_base, self.surface);
        if (self.xdg_surface == null) {
            return error.WaylandCreateXdgSurface;
        }

        // Set up XDG surface listener
        const xdg_surface_listener = wayland.xdg_surface_listener{
            .configure = xdgSurfaceConfigure,
        };
        _ = wayland.xdg_surface_add_listener(self.xdg_surface, &xdg_surface_listener, self);

        // Create toplevel
        self.xdg_toplevel = wayland.xdg_surface_get_toplevel(self.xdg_surface);
        if (self.xdg_toplevel == null) {
            return error.WaylandCreateToplevel;
        }

        // Set up toplevel listener
        const xdg_toplevel_listener = wayland.xdg_toplevel_listener{
            .configure = xdgToplevelConfigure,
            .close = xdgToplevelClose,
        };
        _ = wayland.xdg_toplevel_add_listener(self.xdg_toplevel, &xdg_toplevel_listener, self);

        // Set window properties
        const title_z = try self.allocator.allocSentinel(u8, config.title.len, 0);
        defer self.allocator.free(title_z);
        @memcpy(title_z[0..config.title.len], config.title);
        wayland.xdg_toplevel_set_title(self.xdg_toplevel, title_z);
        wayland.xdg_toplevel_set_app_id(self.xdg_toplevel, "jaguar-app");

        // Commit surface to trigger configure
        wayland.wl_surface_commit(self.surface);

        // Wait for configure
        while (!self.configured) {
            _ = wayland.wl_display_dispatch(self.display);
        }
    }

    fn initEGL(self: *Self) !void {
        // Get EGL display
        self.egl_display = wayland.eglGetDisplay(self.display);
        if (self.egl_display == null) {
            return error.EGLGetDisplay;
        }

        // Initialize EGL
        if (wayland.eglInitialize(self.egl_display, null, null) == 0) {
            return error.EGLInitialize;
        }

        // Choose EGL config
        const config_attribs = [_]c_int{
            0x3024, 8, // EGL_RED_SIZE
            0x3023, 8, // EGL_GREEN_SIZE
            0x3022, 8, // EGL_BLUE_SIZE
            0x3021, 8, // EGL_ALPHA_SIZE
            0x3025, 24, // EGL_DEPTH_SIZE
            0x3026, 8, // EGL_STENCIL_SIZE
            0x3040, 0x0004, // EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT
            0x3038, // EGL_NONE
        };

        var egl_config: wayland.EGLConfig = undefined;
        var num_configs: c_int = undefined;
        if (wayland.eglChooseConfig(self.egl_display, &config_attribs, @ptrCast(&egl_config), 1, &num_configs) == 0 or num_configs == 0) {
            return error.EGLChooseConfig;
        }

        // Create EGL window surface (this would need EGL Wayland extension)
        // For now, create a basic surface
        self.egl_surface = wayland.eglCreateWindowSurface(self.egl_display, egl_config, self.surface, null);
        if (self.egl_surface == null) {
            return error.EGLCreateSurface;
        }

        // Create EGL context
        const context_attribs = [_]c_int{
            0x3098, 3, // EGL_CONTEXT_MAJOR_VERSION
            0x30FB, 3, // EGL_CONTEXT_MINOR_VERSION
            0x30A0, 0x00000001, // EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT
            0x3038, // EGL_NONE
        };

        self.egl_context = wayland.eglCreateContext(self.egl_display, egl_config, null, &context_attribs);
        if (self.egl_context == null) {
            return error.EGLCreateContext;
        }

        // Make context current
        if (wayland.eglMakeCurrent(self.egl_display, self.egl_surface, self.egl_surface, self.egl_context) == 0) {
            return error.EGLMakeCurrent;
        }
    }

    pub fn deinit(self: *Self) void {
        if (self.display) |display| {
            wayland.wl_display_disconnect(display);
        }
    }

    pub fn setCallbacks(self: *Self, window: *@import("window.zig").Window) !void {
        _ = self;
        _ = window;
        // Callbacks are set up during initialization
    }

    pub fn pollEvents(self: *Self) void {
        if (self.display) |display| {
            _ = wayland.wl_display_dispatch_pending(display);
            _ = wayland.wl_display_flush(display);
        }
    }

    pub fn swapBuffers(self: *Self) void {
        if (self.egl_display != null and self.egl_surface != null) {
            _ = wayland.eglSwapBuffers(self.egl_display, self.egl_surface);
        }
    }

    pub fn shouldClose(self: *Self) bool {
        return self.should_close;
    }

    pub fn getSize(self: *Self) [2]u32 {
        return [2]u32{ self.width, self.height };
    }

    pub fn setSize(self: *Self, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
    }

    // Wayland callback functions
    fn registryHandleGlobal(
        data: ?*anyopaque,
        registry: ?*wayland.wl_registry,
        name: u32,
        interface: [*:0]const u8,
        version: u32,
    ) callconv(.C) void {
        const self: *WaylandWindow = @ptrCast(@alignCast(data orelse return));

        const interface_str = std.mem.span(interface);

        if (std.mem.eql(u8, interface_str, "wl_compositor")) {
            self.compositor = @ptrCast(wayland.wl_registry_bind(registry, name, &wayland.wl_compositor_interface, @min(version, 4)));
        } else if (std.mem.eql(u8, interface_str, "xdg_wm_base")) {
            self.xdg_wm_base = @ptrCast(wayland.wl_registry_bind(registry, name, &wayland.xdg_wm_base_interface, @min(version, 1)));
        } else if (std.mem.eql(u8, interface_str, "wl_seat")) {
            self.seat = @ptrCast(wayland.wl_registry_bind(registry, name, &wayland.wl_seat_interface, @min(version, 5)));
            // TODO: Set up seat listener to get pointer and keyboard
        }
    }

    fn registryHandleGlobalRemove(
        data: ?*anyopaque,
        registry: ?*wayland.wl_registry,
        name: u32,
    ) callconv(.C) void {
        _ = data;
        _ = registry;
        _ = name;
        // Handle global removal
    }

    fn xdgWmBasePing(
        data: ?*anyopaque,
        xdg_wm_base: ?*wayland.xdg_wm_base,
        serial: u32,
    ) callconv(.C) void {
        _ = data;
        wayland.xdg_wm_base_pong(xdg_wm_base, serial);
    }

    fn xdgSurfaceConfigure(
        data: ?*anyopaque,
        xdg_surface: ?*wayland.xdg_surface,
        serial: u32,
    ) callconv(.C) void {
        const self: *WaylandWindow = @ptrCast(@alignCast(data orelse return));
        wayland.xdg_surface_ack_configure(xdg_surface, serial);
        self.configured = true;
    }

    fn xdgToplevelConfigure(
        data: ?*anyopaque,
        xdg_toplevel: ?*wayland.xdg_toplevel,
        width: i32,
        height: i32,
        states: ?*wayland.wl_array,
    ) callconv(.C) void {
        _ = xdg_toplevel;
        _ = states;

        const self: *WaylandWindow = @ptrCast(@alignCast(data orelse return));

        if (width > 0 and height > 0) {
            self.width = @intCast(width);
            self.height = @intCast(height);
        }
    }

    fn xdgToplevelClose(
        data: ?*anyopaque,
        xdg_toplevel: ?*wayland.xdg_toplevel,
    ) callconv(.C) void {
        _ = xdg_toplevel;

        const self: *WaylandWindow = @ptrCast(@alignCast(data orelse return));
        self.should_close = true;
    }
};
