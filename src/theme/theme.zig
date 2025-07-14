//! 🐆 Jaguar Theme - Theming and styling system
const std = @import("std");
const Color = @import("../core/widget.zig").Color;

pub const Theme = struct {
    name: []const u8,
    colors: ColorPalette,
    typography: Typography,
    spacing: Spacing,

    pub const LIGHT = Theme{
        .name = "Light",
        .colors = ColorPalette{
            .primary = Color{ .r = 0.2, .g = 0.4, .b = 0.8 },
            .secondary = Color{ .r = 0.4, .g = 0.4, .b = 0.4 },
            .background = Color{ .r = 1.0, .g = 1.0, .b = 1.0 },
            .surface = Color{ .r = 0.95, .g = 0.95, .b = 0.95 },
            .text = Color{ .r = 0.1, .g = 0.1, .b = 0.1 },
            .text_secondary = Color{ .r = 0.4, .g = 0.4, .b = 0.4 },
            .border = Color{ .r = 0.8, .g = 0.8, .b = 0.8 },
            .success = Color{ .r = 0.2, .g = 0.8, .b = 0.2 },
            .warning = Color{ .r = 1.0, .g = 0.6, .b = 0.0 },
            .err = Color{ .r = 0.8, .g = 0.2, .b = 0.2 },
        },
        .typography = Typography{},
        .spacing = Spacing{},
    };

    pub const DARK = Theme{
        .name = "Dark",
        .colors = ColorPalette{
            .primary = Color{ .r = 0.3, .g = 0.5, .b = 0.9 },
            .secondary = Color{ .r = 0.6, .g = 0.6, .b = 0.6 },
            .background = Color{ .r = 0.1, .g = 0.1, .b = 0.1 },
            .surface = Color{ .r = 0.15, .g = 0.15, .b = 0.15 },
            .text = Color{ .r = 0.9, .g = 0.9, .b = 0.9 },
            .text_secondary = Color{ .r = 0.6, .g = 0.6, .b = 0.6 },
            .border = Color{ .r = 0.3, .g = 0.3, .b = 0.3 },
            .success = Color{ .r = 0.3, .g = 0.9, .b = 0.3 },
            .warning = Color{ .r = 1.0, .g = 0.7, .b = 0.1 },
            .err = Color{ .r = 0.9, .g = 0.3, .b = 0.3 },
        },
        .typography = Typography{},
        .spacing = Spacing{},
    };
};

pub const ColorPalette = struct {
    primary: Color,
    secondary: Color,
    background: Color,
    surface: Color,
    text: Color,
    text_secondary: Color,
    border: Color,
    success: Color,
    warning: Color,
    err: Color,
};

pub const Typography = struct {
    font_family: []const u8 = "system-ui",
    font_size_small: f32 = 12.0,
    font_size_normal: f32 = 14.0,
    font_size_large: f32 = 18.0,
    font_size_title: f32 = 24.0,
    line_height: f32 = 1.4,
};

pub const Spacing = struct {
    xs: f32 = 2.0,
    sm: f32 = 4.0,
    md: f32 = 8.0,
    lg: f32 = 16.0,
    xl: f32 = 24.0,
    xxl: f32 = 32.0,
};

pub const ThemeManager = struct {
    current_theme: Theme,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, theme: Theme) Self {
        return Self{
            .current_theme = theme,
            .allocator = allocator,
        };
    }

    pub fn setTheme(self: *Self, theme: Theme) void {
        self.current_theme = theme;
    }

    pub fn getColor(self: *const Self, color_type: ColorType) Color {
        return switch (color_type) {
            .Primary => self.current_theme.colors.primary,
            .Secondary => self.current_theme.colors.secondary,
            .Background => self.current_theme.colors.background,
            .Surface => self.current_theme.colors.surface,
            .Text => self.current_theme.colors.text,
            .TextSecondary => self.current_theme.colors.text_secondary,
            .Border => self.current_theme.colors.border,
            .Success => self.current_theme.colors.success,
            .Warning => self.current_theme.colors.warning,
            .Error => self.current_theme.colors.err,
        };
    }
};

pub const ColorType = enum {
    Primary,
    Secondary,
    Background,
    Surface,
    Text,
    TextSecondary,
    Border,
    Success,
    Warning,
    Error,
};
