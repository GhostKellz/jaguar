//! 🐆 Jaguar Software Backend - CPU-based fallback renderer
const std = @import("std");
const RenderCommand = @import("../gpu_renderer.zig").RenderCommand;
const Color = @import("../../core/widget.zig").Color;
const Rect = @import("../../core/widget.zig").Rect;

pub const SoftwareRenderer = struct {
    allocator: std.mem.Allocator,
    framebuffer: []u32,
    width: u32,
    height: u32,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .framebuffer = &[_]u32{},
            .width = 800,
            .height = 600,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.framebuffer.len > 0) {
            self.allocator.free(self.framebuffer);
        }
    }

    pub fn setViewport(self: *Self, width: f32, height: f32) void {
        const new_width: u32 = @intFromFloat(width);
        const new_height: u32 = @intFromFloat(height);

        if (new_width != self.width or new_height != self.height) {
            self.width = new_width;
            self.height = new_height;

            // Reallocate framebuffer
            if (self.framebuffer.len > 0) {
                self.allocator.free(self.framebuffer);
            }

            const pixel_count = self.width * self.height;
            self.framebuffer = self.allocator.alloc(u32, pixel_count) catch &[_]u32{};
        }
    }

    pub fn executeCommands(self: *Self, commands: []const RenderCommand) !void {
        for (commands) |command| {
            try self.processCommand(command);
        }
    }

    fn processCommand(self: *Self, command: RenderCommand) !void {
        switch (command) {
            .clear => |color| {
                self.clear(color);
            },
            .draw_rect => |rect_cmd| {
                self.drawRect(rect_cmd.rect, rect_cmd.color);
            },
            .draw_text => |text_cmd| {
                // For now, render text as a colored rectangle
                // TODO: Implement proper text rendering
                self.drawRect(text_cmd.rect, text_cmd.color);
            },
            .draw_line => |line_cmd| {
                self.drawLine(line_cmd.start, line_cmd.end, line_cmd.color, line_cmd.width);
            },
            .draw_circle => |circle_cmd| {
                self.drawCircle(circle_cmd.center, circle_cmd.radius, circle_cmd.color);
            },
            else => {
                // Handle other commands
            },
        }
    }

    fn clear(self: *Self, color: Color) void {
        if (self.framebuffer.len == 0) return;

        const pixel_color = self.colorToU32(color);
        @memset(self.framebuffer, pixel_color);
    }

    fn drawRect(self: *Self, rect: Rect, color: Color) void {
        if (self.framebuffer.len == 0) return;

        const pixel_color = self.colorToU32(color);

        const x1: u32 = @intFromFloat(@max(0, rect.x));
        const y1: u32 = @intFromFloat(@max(0, rect.y));
        const x2: u32 = @intFromFloat(@min(@as(f32, @floatFromInt(self.width)), rect.x + rect.width));
        const y2: u32 = @intFromFloat(@min(@as(f32, @floatFromInt(self.height)), rect.y + rect.height));

        var y = y1;
        while (y < y2) : (y += 1) {
            var x = x1;
            while (x < x2) : (x += 1) {
                const index = y * self.width + x;
                if (index < self.framebuffer.len) {
                    self.framebuffer[index] = pixel_color;
                }
            }
        }
    }

    fn drawLine(self: *Self, start: [2]f32, end: [2]f32, color: Color, width: f32) void {
        // Bresenham's line algorithm with thickness
        const x0: i32 = @intFromFloat(start[0]);
        const y0: i32 = @intFromFloat(start[1]);
        const x1: i32 = @intFromFloat(end[0]);
        const y1: i32 = @intFromFloat(end[1]);
        const thickness: i32 = @intFromFloat(@max(1, width));

        const dx: i32 = @intCast(@abs(x1 - x0));
        const dy: i32 = @intCast(@abs(y1 - y0));
        const sx: i32 = if (x0 < x1) 1 else -1;
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err = dx - dy;

        var x = x0;
        var y = y0;

        while (true) {
            // Draw thick point
            var ty: i32 = y - @divTrunc(thickness, 2);
            while (ty <= y + @divTrunc(thickness, 2)) : (ty += 1) {
                var tx: i32 = x - @divTrunc(thickness, 2);
                while (tx <= x + @divTrunc(thickness, 2)) : (tx += 1) {
                    self.setPixel(tx, ty, color);
                }
            }

            if (x == x1 and y == y1) break;

            const e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x += sx;
            }
            if (e2 < dx) {
                err += dx;
                y += sy;
            }
        }
    }

    fn drawCircle(self: *Self, center: [2]f32, radius: f32, color: Color) void {
        // Simple circle drawing using distance check
        const cx: i32 = @intFromFloat(center[0]);
        const cy: i32 = @intFromFloat(center[1]);
        const r: i32 = @intFromFloat(radius);
        const r_squared = r * r;

        var y: i32 = cy - r;
        while (y <= cy + r) : (y += 1) {
            var x: i32 = cx - r;
            while (x <= cx + r) : (x += 1) {
                const dx = x - cx;
                const dy = y - cy;
                if (dx * dx + dy * dy <= r_squared) {
                    self.setPixel(x, y, color);
                }
            }
        }
    }

    fn setPixel(self: *Self, x: i32, y: i32, color: Color) void {
        if (self.framebuffer.len == 0) return;
        if (x < 0 or y < 0) return;

        const ux: u32 = @intCast(x);
        const uy: u32 = @intCast(y);

        if (ux >= self.width or uy >= self.height) return;

        const index = uy * self.width + ux;
        if (index < self.framebuffer.len) {
            self.framebuffer[index] = self.colorToU32(color);
        }
    }

    fn colorToU32(self: *Self, color: Color) u32 {
        _ = self;
        const r: u8 = @intFromFloat(@round(color.r * 255.0));
        const g: u8 = @intFromFloat(@round(color.g * 255.0));
        const b: u8 = @intFromFloat(@round(color.b * 255.0));
        const a: u8 = @intFromFloat(@round(color.a * 255.0));

        return (@as(u32, a) << 24) | (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b);
    }

    pub fn present(self: *Self) !void {
        // In a real implementation, this would copy the framebuffer to the screen
        // For now, we'll just print some debug info
        std.debug.print("Software renderer: presenting frame {}x{}\n", .{ self.width, self.height });
    }
};
