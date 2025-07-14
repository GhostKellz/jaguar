//! 🐆 Jaguar Widgets - Core widget system
const std = @import("std");

pub const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,

    pub const WHITE = Color{ .r = 1.0, .g = 1.0, .b = 1.0 };
    pub const BLACK = Color{ .r = 0.0, .g = 0.0, .b = 0.0 };
    pub const RED = Color{ .r = 1.0, .g = 0.0, .b = 0.0 };
    pub const GREEN = Color{ .r = 0.0, .g = 1.0, .b = 0.0 };
    pub const BLUE = Color{ .r = 0.0, .g = 0.0, .b = 1.0 };
};

pub const WidgetType = enum {
    Text,
    Button,
    Input,
    Slider,
    Checkbox,
    Radio,
    List,
    Container,
    Image,
    Graph,
};

pub const Widget = struct {
    type: WidgetType,
    content: []const u8 = "",
    rect: Rect,
    visible: bool = true,
    enabled: bool = true,
    color: Color = Color.WHITE,
    background_color: ?Color = null,
    border_color: ?Color = null,
    border_width: f32 = 0.0,

    // Widget-specific data
    data: WidgetData = .{ .none = {} },

    // Event callbacks
    on_click: ?*const fn () void = null,
    on_hover: ?*const fn () void = null,
    on_change: ?*const fn ([]const u8) void = null,

    const Self = @This();

    pub fn hitTest(self: *const Self, x: f32, y: f32) bool {
        return x >= self.rect.x and
            x <= self.rect.x + self.rect.width and
            y >= self.rect.y and
            y <= self.rect.y + self.rect.height;
    }
};

pub const WidgetData = union(enum) {
    none: void,
    text: TextData,
    button: ButtonData,
    input: InputData,
    slider: SliderData,
    checkbox: CheckboxData,
    list: ListData,
};

pub const TextData = struct {
    font_size: f32 = 14.0,
    alignment: TextAlignment = .Left,
};

pub const ButtonData = struct {
    pressed: bool = false,
    hovered: bool = false,
};

pub const InputData = struct {
    value: []const u8 = "",
    cursor_pos: usize = 0,
    selected: bool = false,
    placeholder: []const u8 = "",
};

pub const SliderData = struct {
    value: f32 = 0.0,
    min: f32 = 0.0,
    max: f32 = 1.0,
    step: f32 = 0.01,
};

pub const CheckboxData = struct {
    checked: bool = false,
};

pub const ListData = struct {
    items: [][]const u8 = &[_][]const u8{},
    selected_index: ?usize = null,
    scroll_offset: f32 = 0.0,
};

pub const TextAlignment = enum {
    Left,
    Center,
    Right,
};
