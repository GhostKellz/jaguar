const std = @import("std");
const Allocator = std.mem.Allocator;
const WindowConfig = @import("window.zig").WindowConfig;

/// Win32 window implementation for Windows (TODO: Implement)
pub const Win32Window = struct {
    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !Self {
        _ = allocator;
        _ = config;
        return error.Win32NotImplemented;
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn setCallbacks(self: *Self, window: *@import("window.zig").Window) !void {
        _ = self;
        _ = window;
        return error.Win32NotImplemented;
    }

    pub fn pollEvents(self: *Self) void {
        _ = self;
    }

    pub fn swapBuffers(self: *Self) void {
        _ = self;
    }

    pub fn shouldClose(self: *Self) bool {
        _ = self;
        return false;
    }

    pub fn getSize(self: *Self) [2]u32 {
        _ = self;
        return [2]u32{ 800, 600 };
    }

    pub fn setSize(self: *Self, width: u32, height: u32) void {
        _ = self;
        _ = width;
        _ = height;
    }
};
