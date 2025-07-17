//! 🐆 Jaguar WASM Application Example
//! Demonstrates basic GUI functionality in the browser

const std = @import("std");
const jaguar = @import("jaguar");

// Global allocator for WASM
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var wasm_app: ?*jaguar.platform.WasmApp = null;
var ui_context: ?*jaguar.Context = null;

export fn wasm_main() void {
    const allocator = gpa.allocator();

    // Initialize WASM app
    wasm_app = allocator.create(jaguar.platform.WasmApp) catch return;
    wasm_app.?.* = jaguar.platform.WasmApp.init(allocator, .{
        .title = "Jaguar WASM Demo",
        .width = 800,
        .height = 600,
    }) catch return;

    // Initialize UI context
    ui_context = allocator.create(jaguar.Context) catch return;
    ui_context.?.* = jaguar.Context.init(allocator) catch return;

    // Set up demo UI
    setupDemoUI() catch return;

    // Register app instance with JavaScript
    jaguar.platform.wasm.jaguar_wasm_set_app_instance(wasm_app.?);

    jaguar.platform.wasm.jaguar_wasm_log("🐆 Jaguar WASM Demo initialized!");
}

fn setupDemoUI() !void {
    if (ui_context == null) return;

    var ctx = ui_context.?;

    // Create demo widgets
    const title_widget = try ctx.createWidget(.{
        .widget_type = .Text,
        .content = "🐆 Jaguar WASM Demo",
        .rect = jaguar.Rect{ .x = 50, .y = 50, .width = 300, .height = 40 },
        .color = jaguar.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
    });

    const button_widget = try ctx.createWidget(.{
        .widget_type = .Button,
        .content = "Click Me!",
        .rect = jaguar.Rect{ .x = 50, .y = 120, .width = 120, .height = 40 },
        .color = jaguar.Color{ .r = 0.3, .g = 0.7, .b = 1.0, .a = 1.0 },
    });

    const text_input = try ctx.createWidget(.{
        .widget_type = .Input,
        .content = "Type something...",
        .rect = jaguar.Rect{ .x = 50, .y = 180, .width = 300, .height = 30 },
        .color = jaguar.Color{ .r = 0.9, .g = 0.9, .b = 0.9, .a = 1.0 },
    });

    // Add widgets to context
    try ctx.widgets.append(title_widget);
    try ctx.widgets.append(button_widget);
    try ctx.widgets.append(text_input);
}

export fn wasm_frame() void {
    if (wasm_app == null or ui_context == null) return;

    const app = wasm_app.?;
    const ctx = ui_context.?;

    // Poll events
    const events = app.pollEvents() catch return;
    defer app.allocator.free(events);

    // Process events
    for (events) |event| {
        handleEvent(event);
    }

    // Render frame
    app.render(ctx) catch return;
}

fn handleEvent(event: jaguar.events.Event) void {
    switch (event) {
        .mouse_button => |mouse| {
            if (mouse.action == .press) {
                const message = std.fmt.allocPrint(gpa.allocator(), "Mouse clicked at ({d}, {d})", .{ mouse.x, mouse.y }) catch return;
                defer gpa.allocator().free(message);

                // Convert to null-terminated string for JavaScript
                const c_message = gpa.allocator().dupeZ(u8, message) catch return;
                defer gpa.allocator().free(c_message);

                jaguar.platform.wasm.jaguar_wasm_log(c_message.ptr);
            }
        },
        .key_press => |key| {
            if (key.key == .Escape and ui_context != null) {
                // Example: Clear text input on Escape
                for (ui_context.?.widgets.items) |widget| {
                    if (widget.widget_type == .Input) {
                        widget.content = "";
                    }
                }
            }
        },
        .text_input => |text| {
            // Handle text input for focused widgets
            _ = text;
            // This would update the currently focused text input
        },
        .window_resize => |resize| {
            if (wasm_app) |app| {
                app.width = resize.width;
                app.height = resize.height;
            }
        },
        else => {},
    }
}

export fn wasm_cleanup() void {
    if (ui_context) |ctx| {
        ctx.deinit();
        gpa.allocator().destroy(ctx);
        ui_context = null;
    }

    if (wasm_app) |app| {
        app.deinit();
        gpa.allocator().destroy(app);
        wasm_app = null;
    }

    _ = gpa.deinit();

    jaguar.platform.wasm.jaguar_wasm_log("🐆 Jaguar WASM Demo cleanup complete");
}

// Memory management exports for JavaScript
export fn wasm_alloc(size: usize) ?*anyopaque {
    const memory = gpa.allocator().alloc(u8, size) catch return null;
    return memory.ptr;
}

export fn wasm_free(ptr: *anyopaque, size: usize) void {
    const memory: []u8 = @as([*]u8, @ptrCast(ptr))[0..size];
    gpa.allocator().free(memory);
}
