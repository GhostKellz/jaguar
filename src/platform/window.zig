const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Event = @import("../events/event.zig").Event;
const GpuRenderer = @import("../renderer/gpu_renderer.zig").GpuRenderer;

/// Cross-platform window abstraction
pub const Window = struct {
    allocator: Allocator,
    impl: WindowImpl,
    renderer: *GpuRenderer,
    events: ArrayList(Event),
    should_close: bool = false,

    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !*Window {
        const window = try allocator.create(Window);
        window.* = Window{
            .allocator = allocator,
            .impl = try WindowImpl.create(allocator, config),
            .renderer = try allocator.create(GpuRenderer),
            .events = ArrayList(Event).init(allocator),
        };

        // Initialize the GPU renderer with software backend for now
        // TODO: Add OpenGL backend when we have proper context creation
        window.renderer.* = try GpuRenderer.init(allocator, .Software);

        // Set up callbacks
        try window.impl.setCallbacks(window);

        return window;
    }

    pub fn deinit(self: *Window) void {
        self.renderer.deinit();
        self.allocator.destroy(self.renderer);
        self.events.deinit();
        self.impl.deinit();
        self.allocator.destroy(self);
    }

    pub fn pollEvents(self: *Window) []const Event {
        // Clear previous events
        self.events.clearRetainingCapacity();

        // Poll platform events
        self.impl.pollEvents();

        return self.events.items;
    }

    pub fn present(self: *Window) !void {
        try self.renderer.endFrame();
        self.impl.swapBuffers();
    }

    pub fn shouldClose(self: *Window) bool {
        return self.should_close or self.impl.shouldClose();
    }

    pub fn getSize(self: *Window) [2]u32 {
        return self.impl.getSize();
    }

    pub fn setSize(self: *Window, width: u32, height: u32) void {
        self.impl.setSize(width, height);
    }

    pub fn getRenderer(self: *Window) *GpuRenderer {
        return self.renderer;
    }

    // Internal callback functions
    pub fn onWindowClose(self: *Window) !void {
        try self.events.append(.window_close);
        self.should_close = true;
    }

    pub fn onWindowResize(self: *Window, width: u32, height: u32) !void {
        try self.events.append(.{ .window_resize = .{ .width = width, .height = height } });
        self.renderer.setViewport(@floatFromInt(width), @floatFromInt(height));
    }

    pub fn onWindowFocus(self: *Window, focused: bool) !void {
        try self.events.append(.{ .window_focus = .{ .focused = focused } });
    }

    pub fn onKey(self: *Window, key: @import("../events/event.zig").Key, action: @import("../events/event.zig").KeyAction, modifiers: @import("../events/event.zig").KeyModifiers) !void {
        try self.events.append(.{ .key = .{ .key = key, .action = action, .modifiers = modifiers } });
    }

    pub fn onMouseButton(self: *Window, button: @import("../events/event.zig").MouseButton, action: @import("../events/event.zig").MouseAction, modifiers: @import("../events/event.zig").KeyModifiers, x: f64, y: f64) !void {
        try self.events.append(.{ .mouse_button = .{ .button = button, .action = action, .modifiers = modifiers, .x = x, .y = y } });
    }

    pub fn onMouseMove(self: *Window, x: f64, y: f64, dx: f64, dy: f64) !void {
        try self.events.append(.{ .mouse_move = .{ .x = x, .y = y, .dx = dx, .dy = dy } });
    }

    pub fn onMouseScroll(self: *Window, x: f64, y: f64, dx: f64, dy: f64) !void {
        try self.events.append(.{ .mouse_scroll = .{ .x = x, .y = y, .dx = dx, .dy = dy } });
    }

    pub fn onChar(self: *Window, codepoint: u32) !void {
        try self.events.append(.{ .char = .{ .codepoint = codepoint } });
    }
};

pub const WindowConfig = struct {
    title: []const u8 = "Jaguar Window",
    width: u32 = 800,
    height: u32 = 600,
    resizable: bool = true,
    visible: bool = true,
    vsync: bool = true,
};

// Platform-specific implementation with Wayland priority on Linux
const WindowImpl = switch (@import("builtin").os.tag) {
    .linux => WaylandWithFallback,
    .windows => @import("win32_window.zig").Win32Window, // TODO: Implement
    .macos => @import("cocoa_window.zig").CocoaWindow, // TODO: Implement
    .freestanding => @import("wasm_window.zig").WasmWindow,
    else => @compileError("Unsupported platform"),
};

// Wayland-first implementation with X11 fallback for Linux
const WaylandWithFallback = struct {
    impl: union(enum) {
        wayland: @import("wayland_window.zig").WaylandWindow,
        x11: @import("x11_window.zig").X11Window,
    },

    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !Self {
        // Try Wayland first
        if (@import("wayland_window.zig").WaylandWindow.create(allocator, config)) |wayland_window| {
            std.log.info("🌊 Using Wayland for windowing", .{});
            return Self{ .impl = .{ .wayland = wayland_window } };
        } else |wayland_err| {
            std.log.warn("Wayland failed ({}), falling back to X11", .{wayland_err});

            // Fall back to X11
            const x11_window = @import("x11_window.zig").X11Window.create(allocator, config) catch |x11_err| {
                std.log.err("Both Wayland and X11 failed: Wayland={}, X11={}", .{ wayland_err, x11_err });
                return error.NoWindowingSystemAvailable;
            };

            std.log.info("🪟 Using X11 for windowing (fallback)", .{});
            return Self{ .impl = .{ .x11 = x11_window } };
        }
    }

    pub fn deinit(self: *Self) void {
        switch (self.impl) {
            .wayland => |*wayland| wayland.deinit(),
            .x11 => |*x11| x11.deinit(),
        }
    }

    pub fn setCallbacks(self: *Self, window: *@import("window.zig").Window) !void {
        switch (self.impl) {
            .wayland => |*wayland| try wayland.setCallbacks(window),
            .x11 => |*x11| try x11.setCallbacks(window),
        }
    }

    pub fn pollEvents(self: *Self) void {
        switch (self.impl) {
            .wayland => |*wayland| wayland.pollEvents(),
            .x11 => |*x11| x11.pollEvents(),
        }
    }

    pub fn swapBuffers(self: *Self) void {
        switch (self.impl) {
            .wayland => |*wayland| wayland.swapBuffers(),
            .x11 => |*x11| x11.swapBuffers(),
        }
    }

    pub fn shouldClose(self: *Self) bool {
        return switch (self.impl) {
            .wayland => |*wayland| wayland.shouldClose(),
            .x11 => |*x11| x11.shouldClose(),
        };
    }

    pub fn getSize(self: *Self) [2]u32 {
        return switch (self.impl) {
            .wayland => |*wayland| wayland.getSize(),
            .x11 => |*x11| x11.getSize(),
        };
    }

    pub fn setSize(self: *Self, width: u32, height: u32) void {
        switch (self.impl) {
            .wayland => |*wayland| wayland.setSize(width, height),
            .x11 => |*x11| x11.setSize(width, height),
        }
    }
};
