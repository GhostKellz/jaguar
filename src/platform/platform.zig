//! 🐆 Jaguar Platform - Cross-platform abstraction layer
const std = @import("std");
const Event = @import("../core/event.zig").Event;
const Context = @import("../core/context.zig").Context;

// Import platform-specific implementations
const desktop = @import("desktop.zig");
const wasm = @import("wasm.zig");

pub const PlatformConfig = struct {
    title: []const u8,
    width: u32,
    height: u32,
    resizable: bool = true,
};

/// Platform abstraction - routes to appropriate implementation based on target
pub const PlatformApp = switch (@import("builtin").target.os.tag) {
    .freestanding => wasm.WasmApp,  // WASM target
    else => desktop.DesktopApp,      // Native desktop
};

/// Check if we're running on WASM
pub fn isWasm() bool {
    return @import("builtin").target.os.tag == .freestanding;
}

/// Check if we're running on desktop
pub fn isDesktop() bool {
    return !isWasm();
}
