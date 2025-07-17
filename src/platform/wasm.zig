//! 🐆 Jaguar WASM Platform - Browser implementation
const std = @import("std");
const Event = @import("../events/event.zig").Event;
const Context = @import("../core/context.zig").Context;
const PlatformConfig = @import("platform.zig").PlatformConfig;
const GpuRenderer = @import("../renderer/gpu_renderer.zig").GpuRenderer;

// WASM imports from JavaScript
extern fn js_canvas_get_width(canvas_id: [*:0]const u8) u32;
extern fn js_canvas_get_height(canvas_id: [*:0]const u8) u32;
extern fn js_canvas_set_size(canvas_id: [*:0]const u8, width: u32, height: u32) void;
extern fn js_get_time() f64;
extern fn js_request_animation_frame() void;
extern fn js_log(message: [*:0]const u8) void;

// Event queue from JavaScript
var event_queue: std.ArrayList(Event) = undefined;
var event_queue_mutex: std.Thread.Mutex = .{};
var wasm_allocator: std.mem.Allocator = undefined;

pub const WasmApp = struct {
    allocator: std.mem.Allocator,
    title: []const u8,
    width: u32,
    height: u32,
    should_close: bool,
    canvas_id: []const u8,
    renderer: ?*GpuRenderer,
    last_frame_time: f64,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: PlatformConfig) !Self {
        // Initialize global event queue
        wasm_allocator = allocator;
        event_queue = std.ArrayList(Event).init(allocator);

        const canvas_id = "jaguar-canvas";

        // Get initial canvas size from DOM
        const width = js_canvas_get_width(canvas_id);
        const height = js_canvas_get_height(canvas_id);

        js_log("🐆 Jaguar WASM initialized");

        return Self{
            .allocator = allocator,
            .title = config.title,
            .width = width,
            .height = height,
            .should_close = false,
            .canvas_id = canvas_id,
            .renderer = null,
            .last_frame_time = js_get_time(),
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.renderer) |renderer| {
            renderer.deinit();
            self.allocator.destroy(renderer);
        }
        event_queue.deinit();
        js_log("🐆 Jaguar WASM cleanup complete");
    }

    pub fn pollEvents(self: *Self) ![]Event {
        event_queue_mutex.lock();
        defer event_queue_mutex.unlock();

        // Return copy of events and clear the queue
        const events = try self.allocator.dupe(Event, event_queue.items);
        event_queue.clearRetainingCapacity();

        return events;
    }

    pub fn render(self: *Self, context: *Context) !void {
        // Initialize renderer if needed
        if (self.renderer == null) {
            self.renderer = try self.allocator.create(GpuRenderer);
            self.renderer.? = try GpuRenderer.init(self.allocator, .WebGL);
        }

        // Update canvas size if changed
        const current_width = js_canvas_get_width(self.canvas_id.ptr);
        const current_height = js_canvas_get_height(self.canvas_id.ptr);

        if (current_width != self.width or current_height != self.height) {
            self.width = current_width;
            self.height = current_height;
        }

        // Set viewport
        if (self.renderer) |renderer| {
            try renderer.setViewportSize(@floatFromInt(self.width), @floatFromInt(self.height));

            // Render all widgets
            try renderer.render(context.widgets.items);

            // Present frame
            try renderer.endFrame();
        }

        // Update frame timing
        self.last_frame_time = js_get_time();
    }

    pub fn shouldClose(self: *const Self) bool {
        return self.should_close;
    }

    pub fn close(self: *Self) void {
        self.should_close = true;
        js_log("🐆 Jaguar WASM app closing");
    }

    pub fn getFrameTime(self: *const Self) f64 {
        return js_get_time() - self.last_frame_time;
    }

    pub fn requestFrame(self: *Self) void {
        _ = self;
        js_request_animation_frame();
    }
};

// WASM-specific exports for JavaScript interop

var global_app: ?*WasmApp = null;

export fn jaguar_wasm_init(canvas_id: [*:0]const u8, width: u32, height: u32) void {
    _ = canvas_id;
    _ = width;
    _ = height;
    js_log("🐆 Jaguar WASM initialization requested");
    // Note: Actual initialization happens when WasmApp.init() is called from Zig
}

export fn jaguar_wasm_frame() void {
    // This is called by requestAnimationFrame from JavaScript
    // The actual rendering is handled by the main application loop
}

export fn jaguar_wasm_resize(width: u32, height: u32) void {
    if (global_app) |app| {
        app.width = width;
        app.height = height;

        // Add resize event to queue
        event_queue_mutex.lock();
        defer event_queue_mutex.unlock();

        const resize_event = Event{ .window_resize = .{ .width = width, .height = height } };
        event_queue.append(resize_event) catch return;
    }
}

export fn jaguar_wasm_mouse_event(event_type: u32, x: f32, y: f32, button: u32) void {
    event_queue_mutex.lock();
    defer event_queue_mutex.unlock();

    const mouse_event = switch (event_type) {
        0 => Event{ .mouse_button = .{ .button = @enumFromInt(button), .action = .press, .x = x, .y = y } },
        1 => Event{ .mouse_button = .{ .button = @enumFromInt(button), .action = .release, .x = x, .y = y } },
        2 => Event{ .mouse_move = .{ .x = x, .y = y } },
        else => return,
    };

    event_queue.append(mouse_event) catch return;
}

export fn jaguar_wasm_key_event(event_type: u32, key_code: u32, modifiers: u32) void {
    event_queue_mutex.lock();
    defer event_queue_mutex.unlock();

    const key_event = switch (event_type) {
        0 => Event{ .key_press = .{ .key = @enumFromInt(key_code), .modifiers = .{
            .shift = (modifiers & 1) != 0,
            .ctrl = (modifiers & 2) != 0,
            .alt = (modifiers & 4) != 0,
            .super = (modifiers & 8) != 0,
        } } },
        1 => Event{ .key_release = .{ .key = @enumFromInt(key_code), .modifiers = .{
            .shift = (modifiers & 1) != 0,
            .ctrl = (modifiers & 2) != 0,
            .alt = (modifiers & 4) != 0,
            .super = (modifiers & 8) != 0,
        } } },
        else => return,
    };

    event_queue.append(key_event) catch return;
}

export fn jaguar_wasm_scroll_event(x: f32, y: f32, delta_x: f32, delta_y: f32) void {
    event_queue_mutex.lock();
    defer event_queue_mutex.unlock();

    const scroll_event = Event{ .scroll = .{ .x = x, .y = y, .delta_x = delta_x, .delta_y = delta_y } };

    event_queue.append(scroll_event) catch return;
}

export fn jaguar_wasm_text_input(codepoint: u32) void {
    event_queue_mutex.lock();
    defer event_queue_mutex.unlock();

    const text_event = Event{ .text_input = .{ .codepoint = codepoint } };
    event_queue.append(text_event) catch return;
}

export fn jaguar_wasm_set_app_instance(app_ptr: *WasmApp) void {
    global_app = app_ptr;
    js_log("🐆 Jaguar WASM app instance registered");
}

// Utility functions for JavaScript integration
export fn jaguar_wasm_get_canvas_id() [*:0]const u8 {
    if (global_app) |app| {
        return app.canvas_id.ptr;
    }
    return "jaguar-canvas";
}

export fn jaguar_wasm_log(message: [*:0]const u8) void {
    js_log(message);
}
