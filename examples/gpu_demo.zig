//! 🐆 Jaguar GPU Rendering Demo - Showcase the new GPU renderer
const std = @import("std");
const jaguar = @import("jaguar");

// Import GPU renderer from the main API
const GpuRenderer = jaguar.renderer.GpuRenderer;
const GpuBackend = jaguar.renderer.GpuBackend;

pub fn main() !void {
    std.debug.print("🐆 Jaguar GPU Rendering Demo\n", .{});

    // Test different rendering backends
    try testSoftwareRenderer();
    try testOpenGLRenderer();
    try testWebGLRenderer();

    std.debug.print("GPU rendering demo completed! ✨\n", .{});
}

fn testSoftwareRenderer() !void {
    std.debug.print("\n🖥️  Testing Software Renderer...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var renderer = GpuRenderer.init(allocator, .Software) catch |err| {
        std.debug.print("Failed to create software renderer: {}\n", .{err});
        return;
    };
    defer renderer.deinit();

    // Set up viewport
    renderer.setViewportSize(800, 600);

    // Begin frame
    renderer.beginFrame();

    // Draw some test shapes
    renderer.drawRect(.{ .x = 50, .y = 50, .width = 100, .height = 50 }, .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 });

    renderer.drawCircle([2]f32{ 200, 100 }, 30, .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 });

    renderer.drawLine([2]f32{ 50, 200 }, [2]f32{ 150, 250 }, .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, 5.0);

    renderer.drawText("Hello GPU!", .{ .x = 50, .y = 300, .width = 200, .height = 30 }, .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, 16.0);

    // End frame
    renderer.endFrame() catch |err| {
        std.debug.print("Failed to end frame: {}\n", .{err});
        return;
    };

    std.debug.print("✅ Software renderer test completed\n", .{});
}

fn testOpenGLRenderer() !void {
    std.debug.print("\n🚀 Testing OpenGL Renderer...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var renderer = GpuRenderer.init(allocator, .OpenGL) catch |err| {
        std.debug.print("Failed to create OpenGL renderer (expected): {}\n", .{err});
        std.debug.print("⚠️  OpenGL renderer requires windowing system integration\n", .{});
        return;
    };
    defer renderer.deinit();

    std.debug.print("✅ OpenGL renderer initialized (mock)\n", .{});
}

fn testWebGLRenderer() !void {
    std.debug.print("\n🌐 Testing WebGL Renderer...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var renderer = GpuRenderer.init(allocator, .WebGL) catch |err| {
        std.debug.print("Failed to create WebGL renderer (expected): {}\n", .{err});
        std.debug.print("⚠️  WebGL renderer requires browser environment\n", .{});
        return;
    };
    defer renderer.deinit();

    std.debug.print("✅ WebGL renderer initialized (mock)\n", .{});
}
