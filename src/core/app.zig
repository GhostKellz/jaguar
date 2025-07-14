//! 🐆 Jaguar App - Main application entry point
const std = @import("std");
const platform = @import("../platform/platform.zig");
const Context = @import("context.zig").Context;
const Event = @import("event.zig").Event;

pub const AppConfig = struct {
    title: []const u8 = "Jaguar App",
    width: u32 = 800,
    height: u32 = 600,
    resizable: bool = true,
    vsync: bool = true,
    allocator: ?std.mem.Allocator = null,
};

pub const App = struct {
    allocator: std.mem.Allocator,
    platform_app: platform.PlatformApp,
    context: Context,
    running: bool,

    const Self = @This();

    pub fn init(config: AppConfig) !Self {
        const allocator = config.allocator orelse std.heap.page_allocator;
        
        const platform_app = try platform.PlatformApp.init(allocator, .{
            .title = config.title,
            .width = config.width,
            .height = config.height,
            .resizable = config.resizable,
        });

        const context = try Context.init(allocator);

        return Self{
            .allocator = allocator,
            .platform_app = platform_app,
            .context = context,
            .running = false,
        };
    }

    pub fn deinit(self: *Self) void {
        self.context.deinit();
        self.platform_app.deinit();
    }

    /// Start the async event loop
    pub fn run(self: *Self) !void {
        self.running = true;
        
        while (self.running) {
            // Poll platform events
            const events = try self.platform_app.pollEvents();
            
            // Process events through context
            for (events) |event| {
                try self.context.handleEvent(event);
            }

            // Update UI frame
            try self.context.beginFrame();
            
            // User's UI code will be called here via callbacks
            // TODO: Implement UI building phase
            
            try self.context.endFrame();

            // Render the frame
            try self.platform_app.render(&self.context);

            // Check if we should exit
            if (self.platform_app.shouldClose()) {
                self.running = false;
            }
        }
    }

    /// Stop the application
    pub fn quit(self: *Self) void {
        self.running = false;
    }

    /// Create a window (for multi-window support later)
    pub fn window(self: *Self, config: WindowConfig, build_fn: *const fn(*Context) void) !void {
        _ = config;
        build_fn(&self.context);
    }
};

pub const WindowConfig = struct {
    title: []const u8 = "Window",
    width: u32 = 400,
    height: u32 = 300,
};
