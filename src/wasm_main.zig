//! 🐆 Jaguar WASM Entry Point - Browser-specific initialization
const std = @import("std");
const jaguar = @import("jaguar");

// Export functions for JavaScript to call
export fn jaguar_init() void {
    // Initialize the WASM application
}

export fn jaguar_frame() void {
    // Handle a frame update
}

export fn jaguar_resize(width: u32, height: u32) void {
    // Handle window/canvas resize
    _ = width;
    _ = height;
}

export fn jaguar_mouse_move(x: f32, y: f32) void {
    // Handle mouse movement
    _ = x;
    _ = y;
}

export fn jaguar_mouse_click(button: u8, x: f32, y: f32) void {
    // Handle mouse clicks
    _ = button;
    _ = x;
    _ = y;
}

export fn jaguar_key_event(key: u32, pressed: bool) void {
    // Handle keyboard events
    _ = key;
    _ = pressed;
}

// Simple demo function for WASM
export fn demo() u32 {
    return 42;
}

// Custom panic handler for WASM
pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    // In WASM, we can't really do much with panics
    // Just trap the execution
    _ = message;
    while (true) {}
}
