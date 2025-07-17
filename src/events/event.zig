const std = @import("std");

/// Event types for window and input handling
pub const Event = union(enum) {
    window_close,
    window_resize: WindowResizeEvent,
    window_focus: WindowFocusEvent,
    key: KeyEvent,
    mouse_button: MouseButtonEvent,
    mouse_move: MouseMoveEvent,
    mouse_scroll: MouseScrollEvent,
    char: CharEvent,
};

pub const WindowResizeEvent = struct {
    width: u32,
    height: u32,
};

pub const WindowFocusEvent = struct {
    focused: bool,
};

pub const KeyEvent = struct {
    key: Key,
    action: KeyAction,
    modifiers: KeyModifiers,
};

pub const MouseButtonEvent = struct {
    button: MouseButton,
    action: MouseAction,
    modifiers: KeyModifiers,
    x: f64,
    y: f64,
};

pub const MouseMoveEvent = struct {
    x: f64,
    y: f64,
    dx: f64,
    dy: f64,
};

pub const MouseScrollEvent = struct {
    x: f64,
    y: f64,
    dx: f64,
    dy: f64,
};

pub const CharEvent = struct {
    codepoint: u32,
};

pub const Key = enum(u32) {
    unknown = 0,
    space = 32,
    apostrophe = 39,
    comma = 44,
    minus = 45,
    period = 46,
    slash = 47,
    key_0 = 48,
    key_1 = 49,
    key_2 = 50,
    key_3 = 51,
    key_4 = 52,
    key_5 = 53,
    key_6 = 54,
    key_7 = 55,
    key_8 = 56,
    key_9 = 57,
    semicolon = 59,
    equal = 61,
    a = 65,
    b = 66,
    c = 67,
    d = 68,
    e = 69,
    f = 70,
    g = 71,
    h = 72,
    i = 73,
    j = 74,
    k = 75,
    l = 76,
    m = 77,
    n = 78,
    o = 79,
    p = 80,
    q = 81,
    r = 82,
    s = 83,
    t = 84,
    u = 85,
    v = 86,
    w = 87,
    x = 88,
    y = 89,
    z = 90,
    left_bracket = 91,
    backslash = 92,
    right_bracket = 93,
    grave_accent = 96,
    escape = 256,
    enter = 257,
    tab = 258,
    backspace = 259,
    insert = 260,
    delete = 261,
    right = 262,
    left = 263,
    down = 264,
    up = 265,
    page_up = 266,
    page_down = 267,
    home = 268,
    end = 269,
    caps_lock = 280,
    scroll_lock = 281,
    num_lock = 282,
    print_screen = 283,
    pause = 284,
    f1 = 290,
    f2 = 291,
    f3 = 292,
    f4 = 293,
    f5 = 294,
    f6 = 295,
    f7 = 296,
    f8 = 297,
    f9 = 298,
    f10 = 299,
    f11 = 300,
    f12 = 301,
    left_shift = 340,
    left_control = 341,
    left_alt = 342,
    left_super = 343,
    right_shift = 344,
    right_control = 345,
    right_alt = 346,
    right_super = 347,
};

pub const KeyAction = enum(u32) {
    release = 0,
    press = 1,
    repeat = 2,
};

pub const MouseButton = enum(u32) {
    left = 0,
    right = 1,
    middle = 2,
    button_4 = 3,
    button_5 = 4,
    button_6 = 5,
    button_7 = 6,
    button_8 = 7,
};

pub const MouseAction = enum(u32) {
    release = 0,
    press = 1,
};

pub const KeyModifiers = packed struct {
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,

    pub fn fromGlfw(mods: i32) KeyModifiers {
        return KeyModifiers{
            .shift = (mods & 0x0001) != 0,
            .control = (mods & 0x0002) != 0,
            .alt = (mods & 0x0004) != 0,
            .super = (mods & 0x0008) != 0,
            .caps_lock = (mods & 0x0010) != 0,
            .num_lock = (mods & 0x0020) != 0,
        };
    }
};
