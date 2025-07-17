const std = @import("std");
const jaguar = @import("jaguar");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("🐆 Jaguar Windowing Demo", .{});

    // Create window
    const window = try jaguar.Window.create(allocator, .{
        .title = "Jaguar Window Demo",
        .width = 800,
        .height = 600,
        .resizable = true,
    });
    defer window.deinit();

    std.log.info("Window created successfully!", .{});

    // Get the renderer
    const renderer = window.getRenderer();

    // Simple render loop
    var frame_count: u32 = 0;
    while (!window.shouldClose() and frame_count < 60) { // Run for 60 frames
        // Poll events
        const events = window.pollEvents();
        for (events) |event| {
            switch (event) {
                .window_close => std.log.info("Window close event received", .{}),
                .window_resize => |resize| std.log.info("Window resized to {}x{}", .{ resize.width, resize.height }),
                .key => |key_event| std.log.info("Key event: {} ({})", .{ key_event.key, key_event.action }),
                .mouse_button => |mouse| std.log.info("Mouse button: {} at ({}, {})", .{ mouse.button, mouse.x, mouse.y }),
                else => {},
            }
        }

        // Clear background
        renderer.clear(jaguar.Color{ .r = 0.1, .g = 0.2, .b = 0.3, .a = 1.0 });

        // Draw colored rectangle
        renderer.drawRect(jaguar.Rect{ .x = 100, .y = 100, .width = 200, .height = 150 }, jaguar.Color{ .r = 1.0, .g = 0.5, .b = 0.2, .a = 1.0 });

        // Draw commands are added to the renderer's queue automatically
        try window.present();

        frame_count += 1;

        // Small delay to simulate frame rate
        std.time.sleep(16_666_667); // ~60 FPS
    }

    std.log.info("Demo completed! Rendered {} frames ✨", .{frame_count});
}
