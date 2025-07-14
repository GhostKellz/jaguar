//! 🐆 Jaguar - Modern Zig GUI & WASM Toolkit
//! Pure Zig, async-native GUI framework for desktop and web
const std = @import("std");

// Core modules
pub const App = @import("core/app.zig").App;
pub const Context = @import("core/context.zig").Context;
pub const Widget = @import("core/widget.zig").Widget;
pub const Event = @import("core/event.zig").Event;

// Platform abstraction
pub const platform = @import("platform/platform.zig");

// Widget library
pub const widgets = @import("widgets/widgets.zig");

// Rendering
pub const renderer = @import("renderer/renderer.zig");

// Theme system
pub const theme = @import("theme/theme.zig");

// Web/WASM specific
pub const web = @import("web/web.zig");

// Legacy function for compatibility
pub fn bufferedPrint() !void {
    const stdout_file = std.fs.File.stdout().deprecatedWriter();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("🐆 Jaguar GUI Framework v0.1.0\n", .{});
    try bw.flush();
}

test "jaguar core imports" {
    // Basic smoke test to ensure all modules compile
    _ = App;
    _ = Context;
    _ = Widget;
    _ = Event;
}
