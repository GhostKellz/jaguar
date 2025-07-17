//! 🐆 Jaguar Renderer - Cross-platform rendering abstraction
const std = @import("std");
const Widget = @import("../core/widget.zig").Widget;
const Context = @import("../core/context.zig").Context;

// Import the new GPU renderer
const GpuRenderer = @import("gpu_renderer.zig").GpuRenderer;
const GpuBackend = @import("gpu_renderer.zig").GpuBackend;

pub const RenderBackend = enum {
    Software, // CPU-based fallback
    OpenGL, // Desktop OpenGL
    WebGL, // Browser WebGL
    Vulkan, // High-performance Vulkan (future)
};

pub const Renderer = struct {
    backend: RenderBackend,
    allocator: std.mem.Allocator,
    gpu_renderer: ?GpuRenderer = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, backend: RenderBackend) !Self {
        var renderer = Self{
            .backend = backend,
            .allocator = allocator,
        };

        // Initialize GPU renderer based on backend
        const gpu_backend = switch (backend) {
            .Software => GpuBackend.Software,
            .OpenGL => GpuBackend.OpenGL,
            .WebGL => GpuBackend.WebGL,
            .Vulkan => {
                // For now, fall back to software for Vulkan
                std.debug.print("Vulkan not yet implemented, falling back to software rendering\n", .{});
                GpuBackend.Software;
            },
        };

        renderer.gpu_renderer = GpuRenderer.init(allocator, gpu_backend) catch |err| switch (err) {
            else => {
                std.debug.print("Failed to initialize GPU renderer, falling back to software: {}\n", .{err});
                try GpuRenderer.init(allocator, GpuBackend.Software);
            },
        };

        return renderer;
    }

    pub fn deinit(self: *Self) void {
        if (self.gpu_renderer) |*gpu| {
            gpu.deinit();
        }
    }

    pub fn setViewportSize(self: *Self, width: f32, height: f32) void {
        if (self.gpu_renderer) |*gpu| {
            gpu.setViewportSize(width, height);
        }
    }

    pub fn render(self: *Self, widgets: []Widget) !void {
        if (self.gpu_renderer) |*gpu| {
            gpu.beginFrame();

            // Render all widgets
            for (widgets) |*widget| {
                gpu.renderWidget(widget);
            }

            try gpu.endFrame();
        }
    }
};
