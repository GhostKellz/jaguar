//! 🐆 Jaguar GPU Renderer - High-performance GPU-accelerated rendering
const std = @import("std");
const Widget = @import("../core/widget.zig").Widget;
const Context = @import("../core/context.zig").Context;
const Color = @import("../core/widget.zig").Color;
const Rect = @import("../core/widget.zig").Rect;

// Import GPU backend implementations
const opengl = @import("gpu/opengl.zig");
const webgl = @import("gpu/webgl.zig");
const software = @import("gpu/software.zig");

pub const GpuBackend = enum {
    OpenGL,
    WebGL,
    Software,
};

pub const RenderCommand = union(enum) {
    clear: Color,
    draw_rect: struct { rect: Rect, color: Color },
    draw_text: struct { text: []const u8, rect: Rect, color: Color, font_size: f32 },
    draw_image: struct { rect: Rect, texture_id: u32 },
    draw_line: struct { start: [2]f32, end: [2]f32, color: Color, width: f32 },
    draw_circle: struct { center: [2]f32, radius: f32, color: Color },
    set_clip_rect: Rect,
    pop_clip_rect: void,
};

pub const GpuRenderer = struct {
    backend: GpuBackend,
    allocator: std.mem.Allocator,
    commands: std.ArrayList(RenderCommand),
    viewport_size: [2]f32,

    // Backend-specific renderers
    opengl_renderer: ?opengl.OpenGLRenderer = null,
    webgl_renderer: ?webgl.WebGLRenderer = null,
    software_renderer: ?software.SoftwareRenderer = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, backend: GpuBackend) !Self {
        var renderer = Self{
            .backend = backend,
            .allocator = allocator,
            .commands = std.ArrayList(RenderCommand).init(allocator),
            .viewport_size = [2]f32{ 800.0, 600.0 },
        };

        // Initialize the appropriate backend
        switch (backend) {
            .OpenGL => {
                renderer.opengl_renderer = try opengl.OpenGLRenderer.init(allocator);
            },
            .WebGL => {
                renderer.webgl_renderer = try webgl.WebGLRenderer.init(allocator);
            },
            .Software => {
                renderer.software_renderer = try software.SoftwareRenderer.init(allocator);
            },
        }

        return renderer;
    }

    pub fn deinit(self: *Self) void {
        self.commands.deinit();

        switch (self.backend) {
            .OpenGL => if (self.opengl_renderer) |*r| r.deinit(),
            .WebGL => if (self.webgl_renderer) |*r| r.deinit(),
            .Software => if (self.software_renderer) |*r| r.deinit(),
        }
    }

    pub fn setViewportSize(self: *Self, width: f32, height: f32) void {
        self.viewport_size = [2]f32{ width, height };

        switch (self.backend) {
            .OpenGL => if (self.opengl_renderer) |*r| r.setViewport(width, height),
            .WebGL => if (self.webgl_renderer) |*r| r.setViewport(width, height),
            .Software => if (self.software_renderer) |*r| r.setViewport(width, height),
        }
    }

    pub fn beginFrame(self: *Self) void {
        self.commands.clearRetainingCapacity();
        self.clear(Color{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 });
    }

    pub fn endFrame(self: *Self) !void {
        // Execute all commands on the GPU
        try self.executeCommands();

        // Present the frame
        switch (self.backend) {
            .OpenGL => if (self.opengl_renderer) |*r| try r.present(),
            .WebGL => if (self.webgl_renderer) |*r| try r.present(),
            .Software => if (self.software_renderer) |*r| try r.present(),
        }
    }

    // Immediate mode rendering commands

    pub fn clear(self: *Self, color: Color) void {
        self.commands.append(.{ .clear = color }) catch return;
    }

    pub fn drawRect(self: *Self, rect: Rect, color: Color) void {
        self.commands.append(.{ .draw_rect = .{ .rect = rect, .color = color } }) catch return;
    }

    pub fn drawText(self: *Self, text: []const u8, rect: Rect, color: Color, font_size: f32) void {
        self.commands.append(.{ .draw_text = .{ .text = text, .rect = rect, .color = color, .font_size = font_size } }) catch return;
    }

    pub fn drawLine(self: *Self, start: [2]f32, end: [2]f32, color: Color, width: f32) void {
        self.commands.append(.{ .draw_line = .{ .start = start, .end = end, .color = color, .width = width } }) catch return;
    }

    pub fn drawCircle(self: *Self, center: [2]f32, radius: f32, color: Color) void {
        self.commands.append(.{ .draw_circle = .{ .center = center, .radius = radius, .color = color } }) catch return;
    }

    pub fn pushClipRect(self: *Self, rect: Rect) void {
        self.commands.append(.{ .set_clip_rect = rect }) catch return;
    }

    pub fn popClipRect(self: *Self) void {
        self.commands.append(.{ .pop_clip_rect = {} }) catch return;
    }

    // High-level widget rendering
    pub fn renderWidget(self: *Self, widget: *const Widget) void {
        if (!widget.visible) return;

        switch (widget.type) {
            .Text => self.renderTextWidget(widget),
            .Button => self.renderButtonWidget(widget),
            .Input => self.renderInputWidget(widget),
            .Slider => self.renderSliderWidget(widget),
            .Checkbox => self.renderCheckboxWidget(widget),
            else => self.renderGenericWidget(widget),
        }
    }

    fn renderTextWidget(self: *Self, widget: *const Widget) void {
        self.drawText(widget.content, widget.rect, widget.color, 14.0 // Default font size
        );
    }

    fn renderButtonWidget(self: *Self, widget: *const Widget) void {
        // Background
        const bg_color = widget.background_color orelse Color{ .r = 0.3, .g = 0.3, .b = 0.8, .a = 1.0 };
        self.drawRect(widget.rect, bg_color);

        // Border
        if (widget.border_width > 0) {
            const border_color = widget.border_color orelse Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
            // TODO: Implement proper border rendering
            _ = border_color;
        }

        // Text
        self.drawText(widget.content, widget.rect, widget.color, 14.0);
    }

    fn renderInputWidget(self: *Self, widget: *const Widget) void {
        // Background
        const bg_color = widget.background_color orelse Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
        self.drawRect(widget.rect, bg_color);

        // Border
        if (widget.border_width > 0) {
            const border_color = widget.border_color orelse Color{ .r = 0.7, .g = 0.7, .b = 0.7, .a = 1.0 };
            // TODO: Implement proper border rendering
            _ = border_color;
        }

        // Text content or placeholder
        const text = if (widget.content.len > 0) widget.content else switch (widget.data) {
            .input => |input_data| input_data.placeholder,
            else => "",
        };

        self.drawText(text, widget.rect, widget.color, 14.0);
    }

    fn renderSliderWidget(self: *Self, widget: *const Widget) void {
        // Track background
        const track_color = Color{ .r = 0.8, .g = 0.8, .b = 0.8, .a = 1.0 };
        self.drawRect(widget.rect, track_color);

        // Handle position based on value
        if (widget.data == .slider) {
            const slider_data = widget.data.slider;
            const progress = (slider_data.value - slider_data.min) / (slider_data.max - slider_data.min);
            const handle_x = widget.rect.x + progress * widget.rect.width;
            const handle_rect = Rect{
                .x = handle_x - 5,
                .y = widget.rect.y - 5,
                .width = 10,
                .height = widget.rect.height + 10,
            };

            self.drawRect(handle_rect, Color{ .r = 0.3, .g = 0.3, .b = 0.8, .a = 1.0 });
        }
    }

    fn renderCheckboxWidget(self: *Self, widget: *const Widget) void {
        // Box background
        const bg_color = widget.background_color orelse Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
        self.drawRect(widget.rect, bg_color);

        // Border
        if (widget.border_width > 0) {
            const border_color = widget.border_color orelse Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
            // TODO: Implement proper border rendering
            _ = border_color;
        }

        // Check mark if checked
        if (widget.data == .checkbox and widget.data.checkbox.checked) {
            const check_color = Color{ .r = 0.2, .g = 0.8, .b = 0.2, .a = 1.0 };
            // Simple X for now - TODO: Better check mark
            const center_x = widget.rect.x + widget.rect.width / 2;
            const center_y = widget.rect.y + widget.rect.height / 2;
            const size = @min(widget.rect.width, widget.rect.height) * 0.3;

            self.drawLine([2]f32{ center_x - size, center_y - size }, [2]f32{ center_x + size, center_y + size }, check_color, 2.0);
            self.drawLine([2]f32{ center_x - size, center_y + size }, [2]f32{ center_x + size, center_y - size }, check_color, 2.0);
        }
    }

    fn renderGenericWidget(self: *Self, widget: *const Widget) void {
        // Fallback rendering for unknown widget types
        if (widget.background_color) |bg_color| {
            self.drawRect(widget.rect, bg_color);
        }

        if (widget.content.len > 0) {
            self.drawText(widget.content, widget.rect, widget.color, 14.0);
        }
    }

    pub fn executeCommands(self: *Self) !void {
        switch (self.backend) {
            .OpenGL => if (self.opengl_renderer) |*r| try r.executeCommands(self.commands.items),
            .WebGL => if (self.webgl_renderer) |*r| try r.executeCommands(self.commands.items),
            .Software => if (self.software_renderer) |*r| try r.executeCommands(self.commands.items),
        }
    }
};
