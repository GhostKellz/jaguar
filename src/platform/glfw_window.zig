const std = @import("std");
const Allocator = std.mem.Allocator;
const glfw = @import("glfw");
const Event = @import("../events/event.zig");
const WindowConfig = @import("window.zig").WindowConfig;

/// GLFW-based window implementation for desktop platforms
pub const GlfwWindow = struct {
    handle: glfw.Window,
    last_mouse_x: f64 = 0,
    last_mouse_y: f64 = 0,
    first_mouse: bool = true,

    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !Self {
        _ = allocator; // Currently unused

        // Initialize GLFW
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("Failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
            return error.GlfwInitFailed;
        }

        // Configure OpenGL context
        glfw.windowHintTyped(.context_version_major, 3);
        glfw.windowHintTyped(.context_version_minor, 3);
        glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
        glfw.windowHintTyped(.opengl_forward_compat, true);
        glfw.windowHintTyped(.resizable, config.resizable);
        glfw.windowHintTyped(.visible, config.visible);

        // Create window
        const handle = glfw.Window.create(config.width, config.height, config.title, null, null, .{}) orelse {
            const description = glfw.getErrorString();
            std.log.err("Failed to create GLFW window: {?s}", .{description});
            glfw.terminate();
            return error.WindowCreationFailed;
        };

        // Make context current
        glfw.makeContextCurrent(handle);

        // Configure VSync
        glfw.swapInterval(if (config.vsync) 1 else 0);

        return Self{
            .handle = handle,
        };
    }

    pub fn deinit(self: *Self) void {
        self.handle.destroy();
        glfw.terminate();
    }

    pub fn setCallbacks(self: *Self, window: *@import("window.zig").Window) !void {
        // Set user pointer for callbacks
        self.handle.setUserPointer(window);

        // Set up event callbacks
        _ = self.handle.setFramebufferSizeCallback(framebufferSizeCallback);
        _ = self.handle.setWindowCloseCallback(windowCloseCallback);
        _ = self.handle.setWindowFocusCallback(windowFocusCallback);
        _ = self.handle.setKeyCallback(keyCallback);
        _ = self.handle.setMouseButtonCallback(mouseButtonCallback);
        _ = self.handle.setCursorPosCallback(cursorPosCallback);
        _ = self.handle.setScrollCallback(scrollCallback);
        _ = self.handle.setCharCallback(charCallback);
    }

    pub fn pollEvents(self: *Self) void {
        _ = self; // Currently unused
        glfw.pollEvents();
    }

    pub fn swapBuffers(self: *Self) void {
        self.handle.swapBuffers();
    }

    pub fn shouldClose(self: *Self) bool {
        return self.handle.shouldClose();
    }

    pub fn getSize(self: *Self) [2]u32 {
        const size = self.handle.getSize();
        return [2]u32{ @intCast(size.width), @intCast(size.height) };
    }

    pub fn setSize(self: *Self, width: u32, height: u32) void {
        self.handle.setSize(@intCast(width), @intCast(height));
    }

    // GLFW callback functions
    fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
        std.log.err("GLFW error {}: {s}", .{ error_code, description });
    }

    fn framebufferSizeCallback(handle: glfw.Window, width: u32, height: u32) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));
        window.onWindowResize(width, height) catch |err| {
            std.log.err("Error in framebuffer size callback: {}", .{err});
        };
    }

    fn windowCloseCallback(handle: glfw.Window) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));
        window.onWindowClose() catch |err| {
            std.log.err("Error in window close callback: {}", .{err});
        };
    }

    fn windowFocusCallback(handle: glfw.Window, focused: bool) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));
        window.onWindowFocus(focused) catch |err| {
            std.log.err("Error in window focus callback: {}", .{err});
        };
    }

    fn keyCallback(handle: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
        _ = scancode; // Currently unused
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));

        const jaguar_key = glfwKeyToJaguar(key);
        const jaguar_action = glfwActionToJaguar(action);
        const jaguar_mods = glfwModsToJaguar(mods);

        window.onKey(jaguar_key, jaguar_action, jaguar_mods) catch |err| {
            std.log.err("Error in key callback: {}", .{err});
        };
    }

    fn mouseButtonCallback(handle: glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));

        const pos = handle.getCursorPos();
        const jaguar_button = glfwMouseButtonToJaguar(button);
        const jaguar_action = glfwActionToJaguar(action);
        const jaguar_mods = glfwModsToJaguar(mods);

        window.onMouseButton(jaguar_button, jaguar_action, jaguar_mods, pos.xpos, pos.ypos) catch |err| {
            std.log.err("Error in mouse button callback: {}", .{err});
        };
    }

    fn cursorPosCallback(handle: glfw.Window, xpos: f64, ypos: f64) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));

        // Get window implementation to access last mouse position
        var glfw_window: *GlfwWindow = &window.impl;

        var dx: f64 = 0;
        var dy: f64 = 0;

        if (!glfw_window.first_mouse) {
            dx = xpos - glfw_window.last_mouse_x;
            dy = ypos - glfw_window.last_mouse_y;
        } else {
            glfw_window.first_mouse = false;
        }

        glfw_window.last_mouse_x = xpos;
        glfw_window.last_mouse_y = ypos;

        window.onMouseMove(xpos, ypos, dx, dy) catch |err| {
            std.log.err("Error in cursor position callback: {}", .{err});
        };
    }

    fn scrollCallback(handle: glfw.Window, xoffset: f64, yoffset: f64) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));

        const pos = handle.getCursorPos();
        window.onMouseScroll(pos.xpos, pos.ypos, xoffset, yoffset) catch |err| {
            std.log.err("Error in scroll callback: {}", .{err});
        };
    }

    fn charCallback(handle: glfw.Window, codepoint: u32) void {
        const window: *@import("window.zig").Window = @ptrCast(@alignCast(handle.getUserPointer() orelse return));
        window.onChar(codepoint) catch |err| {
            std.log.err("Error in char callback: {}", .{err});
        };
    }

    // Conversion functions from GLFW to Jaguar types
    fn glfwKeyToJaguar(key: glfw.Key) Event.Key {
        return switch (key) {
            .space => .space,
            .apostrophe => .apostrophe,
            .comma => .comma,
            .minus => .minus,
            .period => .period,
            .slash => .slash,
            .@"0" => .key_0,
            .@"1" => .key_1,
            .@"2" => .key_2,
            .@"3" => .key_3,
            .@"4" => .key_4,
            .@"5" => .key_5,
            .@"6" => .key_6,
            .@"7" => .key_7,
            .@"8" => .key_8,
            .@"9" => .key_9,
            .semicolon => .semicolon,
            .equal => .equal,
            .a => .a,
            .b => .b,
            .c => .c,
            .d => .d,
            .e => .e,
            .f => .f,
            .g => .g,
            .h => .h,
            .i => .i,
            .j => .j,
            .k => .k,
            .l => .l,
            .m => .m,
            .n => .n,
            .o => .o,
            .p => .p,
            .q => .q,
            .r => .r,
            .s => .s,
            .t => .t,
            .u => .u,
            .v => .v,
            .w => .w,
            .x => .x,
            .y => .y,
            .z => .z,
            .left_bracket => .left_bracket,
            .backslash => .backslash,
            .right_bracket => .right_bracket,
            .grave_accent => .grave_accent,
            .escape => .escape,
            .enter => .enter,
            .tab => .tab,
            .backspace => .backspace,
            .insert => .insert,
            .delete => .delete,
            .right => .right,
            .left => .left,
            .down => .down,
            .up => .up,
            .page_up => .page_up,
            .page_down => .page_down,
            .home => .home,
            .end => .end,
            .caps_lock => .caps_lock,
            .scroll_lock => .scroll_lock,
            .num_lock => .num_lock,
            .print_screen => .print_screen,
            .pause => .pause,
            .F1 => .f1,
            .F2 => .f2,
            .F3 => .f3,
            .F4 => .f4,
            .F5 => .f5,
            .F6 => .f6,
            .F7 => .f7,
            .F8 => .f8,
            .F9 => .f9,
            .F10 => .f10,
            .F11 => .f11,
            .F12 => .f12,
            .left_shift => .left_shift,
            .left_control => .left_control,
            .left_alt => .left_alt,
            .left_super => .left_super,
            .right_shift => .right_shift,
            .right_control => .right_control,
            .right_alt => .right_alt,
            .right_super => .right_super,
            else => .unknown,
        };
    }

    fn glfwActionToJaguar(action: glfw.Action) Event.KeyAction {
        return switch (action) {
            .release => .release,
            .press => .press,
            .repeat => .repeat,
        };
    }

    fn glfwMouseButtonToJaguar(button: glfw.MouseButton) Event.MouseButton {
        return switch (button) {
            .left => .left,
            .right => .right,
            .middle => .middle,
            else => @enumFromInt(@intFromEnum(button)),
        };
    }

    fn glfwModsToJaguar(mods: glfw.Mods) Event.KeyModifiers {
        return Event.KeyModifiers{
            .shift = mods.shift,
            .control = mods.control,
            .alt = mods.alt,
            .super = mods.super,
            .caps_lock = mods.caps_lock,
            .num_lock = mods.num_lock,
        };
    }
};
