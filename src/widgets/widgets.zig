//! 🐆 Jaguar Widgets - High-level widget library
const std = @import("std");
const CoreWidget = @import("../core/widget.zig").Widget;
const Context = @import("../core/context.zig").Context;

// Re-export core widget types
pub const Widget = @import("../core/widget.zig").Widget;
pub const WidgetType = @import("../core/widget.zig").WidgetType;
pub const Rect = @import("../core/widget.zig").Rect;
pub const Color = @import("../core/widget.zig").Color;

// High-level widget builders
pub fn text(content: []const u8) Widget {
    return Widget{
        .type = .Text,
        .content = content,
        .rect = .{ .x = 0, .y = 0, .width = 200, .height = 20 },
    };
}

pub fn button(label: []const u8, on_click: ?*const fn () void) Widget {
    return Widget{
        .type = .Button,
        .content = label,
        .rect = .{ .x = 0, .y = 0, .width = 100, .height = 30 },
        .on_click = on_click,
        .background_color = Color{ .r = 0.3, .g = 0.3, .b = 0.8 },
        .color = Color.WHITE,
    };
}

pub fn input(placeholder: []const u8) Widget {
    return Widget{
        .type = .Input,
        .content = "",
        .rect = .{ .x = 0, .y = 0, .width = 200, .height = 25 },
        .background_color = Color.WHITE,
        .border_color = Color{ .r = 0.7, .g = 0.7, .b = 0.7 },
        .border_width = 1.0,
        .data = .{ .input = .{ .placeholder = placeholder } },
    };
}

pub fn slider(min: f32, max: f32, value: f32) Widget {
    return Widget{
        .type = .Slider,
        .rect = .{ .x = 0, .y = 0, .width = 200, .height = 20 },
        .background_color = Color{ .r = 0.9, .g = 0.9, .b = 0.9 },
        .data = .{ .slider = .{ .min = min, .max = max, .value = value } },
    };
}

pub fn checkbox(checked: bool) Widget {
    return Widget{
        .type = .Checkbox,
        .rect = .{ .x = 0, .y = 0, .width = 20, .height = 20 },
        .background_color = Color.WHITE,
        .border_color = Color{ .r = 0.5, .g = 0.5, .b = 0.5 },
        .border_width = 1.0,
        .data = .{ .checkbox = .{ .checked = checked } },
    };
}

// Layout helpers
pub const Layout = struct {
    pub fn column(widgets: []Widget) void {
        var y: f32 = 0;
        for (widgets) |*widget| {
            widget.rect.y = y;
            y += widget.rect.height + 5; // 5px spacing
        }
    }

    pub fn row(widgets: []Widget) void {
        var x: f32 = 0;
        for (widgets) |*widget| {
            widget.rect.x = x;
            x += widget.rect.width + 5; // 5px spacing
        }
    }
};
