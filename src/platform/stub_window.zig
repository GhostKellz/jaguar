const std = @import("std");
const Allocator = std.mem.Allocator;
const WindowConfig = @import("window.zig").WindowConfig;

/// Stub window implementation for unsupported platforms or testing
pub const StubWindow = struct {
    width: u32,
    height: u32,
    title: []const u8,
    should_close_flag: bool = false,

    const Self = @This();

    pub fn create(allocator: Allocator, config: WindowConfig) !Self {
        _ = allocator;
        std.log.info("Creating stub window: {s} ({}x{})", .{ config.title, config.width, config.height });
        return Self{
            .width = config.width,
            .height = config.height,
            .title = config.title,
        };
    }

    pub fn deinit(self: *Self) void {
        std.log.info("Destroying stub window: {s}", .{self.title});
    }

    pub fn setCallbacks(self: *Self, window: *@import("window.zig").Window) !void {
        _ = self;
        _ = window;
        // No callbacks needed for stub
    }

    pub fn pollEvents(self: *Self) void {
        _ = self;
        // Simulate some basic events or just return
        // In a real implementation, this would poll the OS event queue
    }

    pub fn swapBuffers(self: *Self) void {
        _ = self;
        // In a real implementation, this would present the framebuffer to the screen
    }

    pub fn shouldClose(self: *Self) bool {
        return self.should_close_flag;
    }

    pub fn getSize(self: *Self) [2]u32 {
        return [2]u32{ self.width, self.height };
    }

    pub fn setSize(self: *Self, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
        std.log.info("Stub window resized to {}x{}", .{ width, height });
    }

    // Helper method to close the window programmatically
    pub fn close(self: *Self) void {
        self.should_close_flag = true;
    }
};
