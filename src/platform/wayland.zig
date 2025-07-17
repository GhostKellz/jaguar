const std = @import("std");

/// Wayland protocol bindings for Zig
/// This is a minimal implementation focusing on core window functionality

// Core Wayland types
pub const wl_display = opaque {};
pub const wl_registry = opaque {};
pub const wl_compositor = opaque {};
pub const wl_surface = opaque {};
pub const wl_shell = opaque {};
pub const wl_shell_surface = opaque {};
pub const wl_seat = opaque {};
pub const wl_pointer = opaque {};
pub const wl_keyboard = opaque {};
pub const wl_shm = opaque {};
pub const wl_shm_pool = opaque {};
pub const wl_buffer = opaque {};
pub const wl_callback = opaque {};

// XDG Shell (preferred modern protocol)
pub const xdg_wm_base = opaque {};
pub const xdg_surface = opaque {};
pub const xdg_toplevel = opaque {};

// EGL types for OpenGL
pub const EGLDisplay = ?*anyopaque;
pub const EGLSurface = ?*anyopaque;
pub const EGLContext = ?*anyopaque;
pub const EGLConfig = ?*anyopaque;

// Wayland interface structures
pub const wl_interface = extern struct {
    name: [*:0]const u8,
    version: c_int,
    method_count: c_int,
    methods: ?[*]const wl_message,
    event_count: c_int,
    events: ?[*]const wl_message,
};

pub const wl_message = extern struct {
    name: [*:0]const u8,
    signature: [*:0]const u8,
    types: ?[*]const ?*const wl_interface,
};

pub const wl_proxy = opaque {};

// Function pointer types
pub const wl_registry_listener = extern struct {
    global: ?*const fn (
        data: ?*anyopaque,
        registry: ?*wl_registry,
        name: u32,
        interface: [*:0]const u8,
        version: u32,
    ) callconv(.C) void,
    global_remove: ?*const fn (
        data: ?*anyopaque,
        registry: ?*wl_registry,
        name: u32,
    ) callconv(.C) void,
};

pub const xdg_wm_base_listener = extern struct {
    ping: ?*const fn (
        data: ?*anyopaque,
        xdg_wm_base: ?*xdg_wm_base,
        serial: u32,
    ) callconv(.C) void,
};

pub const xdg_surface_listener = extern struct {
    configure: ?*const fn (
        data: ?*anyopaque,
        xdg_surface: ?*xdg_surface,
        serial: u32,
    ) callconv(.C) void,
};

pub const xdg_toplevel_listener = extern struct {
    configure: ?*const fn (
        data: ?*anyopaque,
        xdg_toplevel: ?*xdg_toplevel,
        width: i32,
        height: i32,
        states: ?*wl_array,
    ) callconv(.C) void,
    close: ?*const fn (
        data: ?*anyopaque,
        xdg_toplevel: ?*xdg_toplevel,
    ) callconv(.C) void,
};

pub const wl_pointer_listener = extern struct {
    enter: ?*const fn (
        data: ?*anyopaque,
        pointer: ?*wl_pointer,
        serial: u32,
        surface: ?*wl_surface,
        surface_x: i32, // actually wl_fixed_t
        surface_y: i32, // actually wl_fixed_t
    ) callconv(.C) void,
    leave: ?*const fn (
        data: ?*anyopaque,
        pointer: ?*wl_pointer,
        serial: u32,
        surface: ?*wl_surface,
    ) callconv(.C) void,
    motion: ?*const fn (
        data: ?*anyopaque,
        pointer: ?*wl_pointer,
        time: u32,
        surface_x: i32, // actually wl_fixed_t
        surface_y: i32, // actually wl_fixed_t
    ) callconv(.C) void,
    button: ?*const fn (
        data: ?*anyopaque,
        pointer: ?*wl_pointer,
        serial: u32,
        time: u32,
        button: u32,
        state: u32,
    ) callconv(.C) void,
    axis: ?*const fn (
        data: ?*anyopaque,
        pointer: ?*wl_pointer,
        time: u32,
        axis: u32,
        value: i32, // actually wl_fixed_t
    ) callconv(.C) void,
};

pub const wl_keyboard_listener = extern struct {
    keymap: ?*const fn (
        data: ?*anyopaque,
        keyboard: ?*wl_keyboard,
        format: u32,
        fd: i32,
        size: u32,
    ) callconv(.C) void,
    enter: ?*const fn (
        data: ?*anyopaque,
        keyboard: ?*wl_keyboard,
        serial: u32,
        surface: ?*wl_surface,
        keys: ?*wl_array,
    ) callconv(.C) void,
    leave: ?*const fn (
        data: ?*anyopaque,
        keyboard: ?*wl_keyboard,
        serial: u32,
        surface: ?*wl_surface,
    ) callconv(.C) void,
    key: ?*const fn (
        data: ?*anyopaque,
        keyboard: ?*wl_keyboard,
        serial: u32,
        time: u32,
        key: u32,
        state: u32,
    ) callconv(.C) void,
    modifiers: ?*const fn (
        data: ?*anyopaque,
        keyboard: ?*wl_keyboard,
        serial: u32,
        mods_depressed: u32,
        mods_latched: u32,
        mods_locked: u32,
        group: u32,
    ) callconv(.C) void,
};

pub const wl_array = extern struct {
    size: usize,
    alloc: usize,
    data: ?*anyopaque,
};

// Wayland enums
pub const WL_POINTER_BUTTON_STATE_RELEASED: u32 = 0;
pub const WL_POINTER_BUTTON_STATE_PRESSED: u32 = 1;

pub const WL_KEYBOARD_KEY_STATE_RELEASED: u32 = 0;
pub const WL_KEYBOARD_KEY_STATE_PRESSED: u32 = 1;

// Mouse buttons (from linux/input.h)
pub const BTN_LEFT: u32 = 0x110;
pub const BTN_RIGHT: u32 = 0x111;
pub const BTN_MIDDLE: u32 = 0x112;

// External function declarations (will be loaded dynamically)
pub extern fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
pub extern fn wl_display_disconnect(display: ?*wl_display) void;
pub extern fn wl_display_get_registry(display: ?*wl_display) ?*wl_registry;
pub extern fn wl_display_roundtrip(display: ?*wl_display) c_int;
pub extern fn wl_display_dispatch(display: ?*wl_display) c_int;
pub extern fn wl_display_dispatch_pending(display: ?*wl_display) c_int;
pub extern fn wl_display_flush(display: ?*wl_display) c_int;

pub extern fn wl_registry_add_listener(
    registry: ?*wl_registry,
    listener: *const wl_registry_listener,
    data: ?*anyopaque,
) c_int;

pub extern fn wl_registry_bind(
    registry: ?*wl_registry,
    name: u32,
    interface: *const wl_interface,
    version: u32,
) ?*wl_proxy;

pub extern fn wl_compositor_create_surface(compositor: ?*wl_compositor) ?*wl_surface;

pub extern fn xdg_wm_base_add_listener(
    xdg_wm_base: ?*xdg_wm_base,
    listener: *const xdg_wm_base_listener,
    data: ?*anyopaque,
) c_int;

pub extern fn xdg_wm_base_get_xdg_surface(
    xdg_wm_base: ?*xdg_wm_base,
    surface: ?*wl_surface,
) ?*xdg_surface;

pub extern fn xdg_wm_base_pong(xdg_wm_base: ?*xdg_wm_base, serial: u32) void;

pub extern fn xdg_surface_add_listener(
    xdg_surface: ?*xdg_surface,
    listener: *const xdg_surface_listener,
    data: ?*anyopaque,
) c_int;

pub extern fn xdg_surface_get_toplevel(xdg_surface: ?*xdg_surface) ?*xdg_toplevel;
pub extern fn xdg_surface_ack_configure(xdg_surface: ?*xdg_surface, serial: u32) void;

pub extern fn xdg_toplevel_add_listener(
    xdg_toplevel: ?*xdg_toplevel,
    listener: *const xdg_toplevel_listener,
    data: ?*anyopaque,
) c_int;

pub extern fn xdg_toplevel_set_title(xdg_toplevel: ?*xdg_toplevel, title: [*:0]const u8) void;
pub extern fn xdg_toplevel_set_app_id(xdg_toplevel: ?*xdg_toplevel, app_id: [*:0]const u8) void;

pub extern fn wl_surface_commit(surface: ?*wl_surface) void;
pub extern fn wl_surface_damage(surface: ?*wl_surface, x: i32, y: i32, width: i32, height: i32) void;
pub extern fn wl_surface_attach(surface: ?*wl_surface, buffer: ?*wl_buffer, x: i32, y: i32) void;

// EGL functions for OpenGL context
pub extern fn eglGetDisplay(display_id: ?*anyopaque) EGLDisplay;
pub extern fn eglInitialize(dpy: EGLDisplay, major: ?*c_int, minor: ?*c_int) c_int;
pub extern fn eglChooseConfig(
    dpy: EGLDisplay,
    attrib_list: ?[*]const c_int,
    configs: ?[*]EGLConfig,
    config_size: c_int,
    num_config: ?*c_int,
) c_int;
pub extern fn eglCreateWindowSurface(
    dpy: EGLDisplay,
    config: EGLConfig,
    win: ?*anyopaque,
    attrib_list: ?[*]const c_int,
) EGLSurface;
pub extern fn eglCreateContext(
    dpy: EGLDisplay,
    config: EGLConfig,
    share_context: EGLContext,
    attrib_list: ?[*]const c_int,
) EGLContext;
pub extern fn eglMakeCurrent(
    dpy: EGLDisplay,
    draw: EGLSurface,
    read: EGLSurface,
    ctx: EGLContext,
) c_int;
pub extern fn eglSwapBuffers(dpy: EGLDisplay, surface: EGLSurface) c_int;

// Interface declarations (these would normally come from protocol XML)
pub extern const wl_compositor_interface: wl_interface;
pub extern const wl_seat_interface: wl_interface;
pub extern const wl_shm_interface: wl_interface;
pub extern const xdg_wm_base_interface: wl_interface;

// Helper function to convert fixed-point to float
pub fn wl_fixed_to_double(f: i32) f64 {
    const union_val = @as(u64, @bitCast(@as(i64, f)));
    return @as(f64, @floatFromInt(@as(i32, @intCast(union_val >> 8)))) +
        @as(f64, @floatFromInt(@as(i32, @intCast(union_val & 0xff)))) / 256.0;
}
