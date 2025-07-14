//! 🐆 Jaguar Events - Platform event system
const std = @import("std");

pub const Event = union(enum) {
    MouseMove: [2]f32, // x, y
    MouseDown: u8, // button index (0=left, 1=right, 2=middle)
    MouseUp: u8, // button index
    MouseWheel: [2]f32, // dx, dy
    KeyDown: u32, // key code
    KeyUp: u32, // key code
    TextInput: []const u8, // UTF-8 text
    WindowResize: [2]u32, // width, height
    WindowClose,
    WindowFocus: bool, // gained/lost focus
    WindowMinimize: bool, // minimized/restored
};

pub const KeyCode = struct {
    pub const ESCAPE: u32 = 1;
    pub const ENTER: u32 = 13;
    pub const SPACE: u32 = 32;
    pub const LEFT: u32 = 37;
    pub const UP: u32 = 38;
    pub const RIGHT: u32 = 39;
    pub const DOWN: u32 = 40;
    // Add more as needed
};

pub const MouseButton = struct {
    pub const LEFT: u8 = 0;
    pub const RIGHT: u8 = 1;
    pub const MIDDLE: u8 = 2;
};

/// Event queue for async event processing
pub const EventQueue = struct {
    events: std.ArrayList(Event),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .events = std.ArrayList(Event).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.events.deinit();
    }

    pub fn push(self: *Self, event: Event) !void {
        try self.events.append(event);
    }

    pub fn poll(self: *Self) []Event {
        const events = self.events.toOwnedSlice() catch &[_]Event{};
        return events;
    }
};
