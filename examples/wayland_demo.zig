const std = @import("std");
const jaguar = @import("jaguar");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("🐆 Jaguar Wayland Window Demo", .{});

    // Create window
    const window = jaguar.Window.create(allocator, .{
        .title = "Jaguar Wayland Demo",
        .width = 800,
        .height = 600,
        .resizable = true,
    }) catch |err| {
        std.log.err("Failed to create window: {}", .{err});
        return;
    };
    defer window.deinit();

    std.log.info("✅ Window created successfully!", .{});
    std.log.info("🌊 Running Wayland event loop...", .{});

    // Main event loop
    while (!window.shouldClose()) {
        const events = window.pollEvents();

        for (events) |event| {
            switch (event) {
                .window_close => {
                    std.log.info("🚪 Window close requested", .{});
                },
                .window_resize => |resize| {
                    std.log.info("📏 Window resized: {}x{}", .{ resize.width, resize.height });
                },
                .key => |key_event| {
                    if (key_event.action == .press) {
                        switch (key_event.key) {
                            .escape => {
                                std.log.info("🔐 Escape pressed - closing window", .{});
                                break;
                            },
                            .q => {
                                if (key_event.modifiers.control) {
                                    std.log.info("🔐 Ctrl+Q pressed - closing window", .{});
                                    break;
                                }
                            },
                            else => {
                                std.log.info("⌨️  Key pressed: {}", .{key_event.key});
                            },
                        }
                    }
                },
                .mouse_button => |mouse| {
                    if (mouse.action == .press) {
                        std.log.info("🖱️  Mouse button {} pressed at ({d:.1}, {d:.1})", .{ mouse.button, mouse.x, mouse.y });
                    }
                },
                .mouse_move => |mouse| {
                    // Only log significant movements to avoid spam
                    if (@abs(mouse.dx) > 5 or @abs(mouse.dy) > 5) {
                        std.log.debug("🖱️  Mouse moved to ({d:.1}, {d:.1})", .{ mouse.x, mouse.y });
                    }
                },
                else => {},
            }
        }

        // Render (for now just clear the screen)
        const renderer = window.getRenderer();
        // Clear background
        renderer.clear(jaguar.renderer.Color{ .r = 0.1, .g = 0.1, .b = 0.2, .a = 1.0 });

        // Draw colored rectangle
        renderer.drawRect(jaguar.Rect{ .x = 100, .y = 100, .width = 200, .height = 100 }, jaguar.renderer.Color{ .r = 0.8, .g = 0.3, .b = 0.3, .a = 1.0 });

        // Draw text
        renderer.drawText("Wayland + Jaguar! 🐆", jaguar.Rect{ .x = 50, .y = 50, .width = 300, .height = 30 }, jaguar.renderer.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, 16.0);

        try window.present();

        // Small delay to prevent busy waiting
        std.time.sleep(16_666_667); // ~60 FPS
    }

    std.log.info("🌊 Wayland window demo completed! ✨", .{});
}
