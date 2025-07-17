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

// Windowing system (new)
pub const Window = @import("platform/window.zig").Window;
pub const WindowConfig = @import("platform/window.zig").WindowConfig;

// Events (new)
pub const events = struct {
    pub const Event = @import("events/event.zig").Event;
    pub const Key = @import("events/event.zig").Key;
    pub const KeyAction = @import("events/event.zig").KeyAction;
    pub const MouseButton = @import("events/event.zig").MouseButton;
    pub const MouseAction = @import("events/event.zig").MouseAction;
    pub const KeyModifiers = @import("events/event.zig").KeyModifiers;
};

// Widget library
pub const widgets = @import("widgets/widgets.zig");

// Rendering system
pub const renderer = struct {
    pub const Renderer = @import("renderer/renderer.zig").Renderer;
    pub const RenderBackend = @import("renderer/renderer.zig").RenderBackend;
    pub const GpuRenderer = @import("renderer/gpu_renderer.zig").GpuRenderer;
    pub const GpuBackend = @import("renderer/gpu_renderer.zig").GpuBackend;
    pub const RenderCommand = @import("renderer/gpu_renderer.zig").RenderCommand;
    pub const Color = @import("core/widget.zig").Color;
};

// Convenience exports at top level
pub const RenderCommand = @import("renderer/gpu_renderer.zig").RenderCommand;
pub const Color = @import("core/widget.zig").Color;
pub const Rect = @import("core/widget.zig").Rect;

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
