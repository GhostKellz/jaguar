//! 🐆 Jaguar Context - UI rendering and state management context
const std = @import("std");
const Event = @import("event.zig").Event;
const Widget = @import("widget.zig").Widget;

pub const Context = struct {
    allocator: std.mem.Allocator,
    widgets: std.ArrayList(Widget),
    current_frame: u64,
    mouse_pos: [2]f32,
    mouse_down: [3]bool, // left, right, middle
    keys_down: std.AutoArrayHashMap(u32, bool),
    
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .widgets = std.ArrayList(Widget).init(allocator),
            .current_frame = 0,
            .mouse_pos = [2]f32{ 0.0, 0.0 },
            .mouse_down = [3]bool{ false, false, false },
            .keys_down = std.AutoArrayHashMap(u32, bool).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.widgets.deinit();
        self.keys_down.deinit();
    }

    /// Begin a new UI frame
    pub fn beginFrame(self: *Self) !void {
        self.current_frame += 1;
        self.widgets.clearRetainingCapacity();
    }

    /// End the current UI frame
    pub fn endFrame(self: *Self) !void {
        // Layout and prepare widgets for rendering
        // TODO: Implement layout algorithm
        _ = self;
    }

    /// Handle platform events
    pub fn handleEvent(self: *Self, event: Event) !void {
        switch (event) {
            .MouseMove => |pos| {
                self.mouse_pos = pos;
            },
            .MouseDown => |btn| {
                if (btn < 3) {
                    self.mouse_down[btn] = true;
                }
            },
            .MouseUp => |btn| {
                if (btn < 3) {
                    self.mouse_down[btn] = false;
                }
            },
            .KeyDown => |key| {
                try self.keys_down.put(key, true);
            },
            .KeyUp => |key| {
                try self.keys_down.put(key, false);
            },
            .WindowResize => |size| {
                // Handle window resize
                _ = size;
            },
            .WindowClose => {
                // Handle window close request
            },
        }
    }

    /// Add a widget to the current frame
    pub fn addWidget(self: *Self, widget: Widget) !void {
        try self.widgets.append(widget);
    }

    // Immediate mode UI helpers
    
    /// Create a text widget
    pub fn text(self: *Self, content: []const u8) !void {
        try self.addWidget(Widget{
            .type = .Text,
            .content = content,
            .rect = .{ .x = 0, .y = 0, .width = 100, .height = 20 },
        });
    }

    /// Create a button widget
    pub fn button(self: *Self, label: []const u8, config: ButtonConfig) !bool {
        const widget = Widget{
            .type = .Button,
            .content = label,
            .rect = .{ .x = 0, .y = 0, .width = 100, .height = 30 },
        };
        
        try self.addWidget(widget);
        
        // Check if button was clicked
        // TODO: Implement proper hit testing
        _ = config;
        return false;
    }

    /// Show a notification
    pub fn notify(self: *Self, message: []const u8) void {
        // TODO: Implement notification system
        _ = self;
        std.debug.print("Notification: {s}\n", .{message});
    }

    /// Reload the application (useful for web)
    pub fn reload(self: *Self) void {
        // TODO: Implement reload functionality
        _ = self;
        std.debug.print("Reload requested\n", .{});
    }
};

pub const ButtonConfig = struct {
    onClick: ?*const fn(*Context) void = null,
};
