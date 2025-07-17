//! 🤖 ZEKE - AI Chat Application (WASM Version)
//! Claude-Code replacement built with Jaguar GUI framework

const std = @import("std");
const jaguar = @import("jaguar");

// Global state for ZEKE
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var zeke_app: ?*ZekeApp = null;

const ZekeApp = struct {
    wasm_app: *jaguar.platform.WasmApp,
    ui_context: *jaguar.Context,
    chat_history: std.ArrayList(ChatMessage),
    current_input: []u8,
    is_ai_typing: bool,

    const ChatMessage = struct {
        role: enum { user, assistant },
        content: []const u8,
        timestamp: i64,
    };

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);

        // Initialize WASM app
        self.wasm_app = try allocator.create(jaguar.platform.WasmApp);
        self.wasm_app.* = try jaguar.platform.WasmApp.init(allocator, .{
            .title = "🤖 ZEKE - AI Chat",
            .width = 1200,
            .height = 800,
        });

        // Initialize UI context
        self.ui_context = try allocator.create(jaguar.Context);
        self.ui_context.* = try jaguar.Context.init(allocator);

        // Initialize chat state
        self.chat_history = std.ArrayList(ChatMessage).init(allocator);
        self.current_input = try allocator.alloc(u8, 1024);
        @memset(self.current_input, 0);
        self.is_ai_typing = false;

        try self.setupUI();

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.chat_history.deinit();
        self.wasm_app.allocator.free(self.current_input);
        self.ui_context.deinit();
        self.wasm_app.allocator.destroy(self.ui_context);
        self.wasm_app.deinit();
        self.wasm_app.allocator.destroy(self.wasm_app);
    }

    fn setupUI(self: *Self) !void {
        const ctx = self.ui_context;

        // Title bar
        const title = try ctx.createWidget(.{
            .widget_type = .Text,
            .content = "🤖 ZEKE - Your AI Coding Assistant",
            .rect = jaguar.Rect{ .x = 20, .y = 20, .width = 400, .height = 40 },
            .color = jaguar.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
        });

        // Chat area background
        const chat_bg = try ctx.createWidget(.{
            .widget_type = .Panel,
            .content = "",
            .rect = jaguar.Rect{ .x = 20, .y = 80, .width = 760, .height = 500 },
            .color = jaguar.Color{ .r = 0.15, .g = 0.15, .b = 0.18, .a = 1.0 },
        });

        // Welcome message
        const welcome = try ctx.createWidget(.{
            .widget_type = .Text,
            .content = "👋 Welcome to ZEKE! I'm your AI coding assistant.\nAsk me about code, debugging, or anything programming-related.",
            .rect = jaguar.Rect{ .x = 40, .y = 100, .width = 720, .height = 60 },
            .color = jaguar.Color{ .r = 0.8, .g = 0.9, .b = 1.0, .a = 1.0 },
        });

        // Input area background
        const input_bg = try ctx.createWidget(.{
            .widget_type = .Panel,
            .content = "",
            .rect = jaguar.Rect{ .x = 20, .y = 600, .width = 760, .height = 120 },
            .color = jaguar.Color{ .r = 0.12, .g = 0.12, .b = 0.15, .a = 1.0 },
        });

        // Text input
        const text_input = try ctx.createWidget(.{
            .widget_type = .Input,
            .content = "Type your question here...",
            .rect = jaguar.Rect{ .x = 40, .y = 620, .width = 600, .height = 40 },
            .color = jaguar.Color{ .r = 0.2, .g = 0.2, .b = 0.25, .a = 1.0 },
        });

        // Send button
        const send_button = try ctx.createWidget(.{
            .widget_type = .Button,
            .content = "💬 Send",
            .rect = jaguar.Rect{ .x = 660, .y = 620, .width = 100, .height = 40 },
            .color = jaguar.Color{ .r = 0.2, .g = 0.6, .b = 1.0, .a = 1.0 },
        });

        // AI provider selector
        const provider_label = try ctx.createWidget(.{
            .widget_type = .Text,
            .content = "AI Provider:",
            .rect = jaguar.Rect{ .x = 40, .y = 680, .width = 100, .height = 20 },
            .color = jaguar.Color{ .r = 0.7, .g = 0.7, .b = 0.7, .a = 1.0 },
        });

        const provider_dropdown = try ctx.createWidget(.{
            .widget_type = .Dropdown,
            .content = "Claude (Anthropic)",
            .rect = jaguar.Rect{ .x = 150, .y = 675, .width = 150, .height = 30 },
            .color = jaguar.Color{ .r = 0.3, .g = 0.3, .b = 0.35, .a = 1.0 },
        });

        // Sidebar
        const sidebar = try ctx.createWidget(.{
            .widget_type = .Panel,
            .content = "",
            .rect = jaguar.Rect{ .x = 800, .y = 80, .width = 380, .height = 640 },
            .color = jaguar.Color{ .r = 0.1, .g = 0.1, .b = 0.12, .a = 1.0 },
        });

        // Sidebar title
        const sidebar_title = try ctx.createWidget(.{
            .widget_type = .Text,
            .content = "🔧 Quick Actions",
            .rect = jaguar.Rect{ .x = 820, .y = 100, .width = 200, .height = 30 },
            .color = jaguar.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
        });

        // Quick action buttons
        const actions = [_]struct { text: []const u8, y: f32 }{
            .{ .text = "📝 Explain Code", .y = 150 },
            .{ .text = "🐛 Debug Help", .y = 190 },
            .{ .text = "🚀 Optimize Code", .y = 230 },
            .{ .text = "📚 Learn Concept", .y = 270 },
            .{ .text = "🔄 Refactor", .y = 310 },
            .{ .text = "🧪 Write Tests", .y = 350 },
        };

        for (actions) |action| {
            const button = try ctx.createWidget(.{
                .widget_type = .Button,
                .content = action.text,
                .rect = jaguar.Rect{ .x = 820, .y = action.y, .width = 340, .height = 30 },
                .color = jaguar.Color{ .r = 0.25, .g = 0.25, .b = 0.3, .a = 1.0 },
            });
            try ctx.widgets.append(button);
        }

        // Add main widgets
        try ctx.widgets.append(title);
        try ctx.widgets.append(chat_bg);
        try ctx.widgets.append(welcome);
        try ctx.widgets.append(input_bg);
        try ctx.widgets.append(text_input);
        try ctx.widgets.append(send_button);
        try ctx.widgets.append(provider_label);
        try ctx.widgets.append(provider_dropdown);
        try ctx.widgets.append(sidebar);
        try ctx.widgets.append(sidebar_title);
    }

    pub fn handleEvent(self: *Self, event: jaguar.events.Event) void {
        switch (event) {
            .mouse_button => |mouse| {
                if (mouse.action == .press) {
                    self.handleClick(mouse.x, mouse.y);
                }
            },
            .key_press => |key| {
                if (key.key == .Enter and key.modifiers.ctrl) {
                    self.sendMessage();
                } else if (key.key == .Escape) {
                    self.clearInput();
                }
            },
            .text_input => |text| {
                self.appendToInput(text.codepoint);
            },
            else => {},
        }
    }

    fn handleClick(self: *Self, x: f32, y: f32) void {
        // Check if send button was clicked
        if (x >= 660 and x <= 760 and y >= 620 and y <= 660) {
            self.sendMessage();
        }

        // Check quick action buttons
        const quick_actions = [_]struct { y_start: f32, y_end: f32, action: []const u8 }{
            .{ .y_start = 150, .y_end = 180, .action = "explain" },
            .{ .y_start = 190, .y_end = 220, .action = "debug" },
            .{ .y_start = 230, .y_end = 260, .action = "optimize" },
            .{ .y_start = 270, .y_end = 300, .action = "learn" },
            .{ .y_start = 310, .y_end = 340, .action = "refactor" },
            .{ .y_start = 350, .y_end = 380, .action = "test" },
        };

        if (x >= 820 and x <= 1160) {
            for (quick_actions) |qa| {
                if (y >= qa.y_start and y <= qa.y_end) {
                    self.handleQuickAction(qa.action);
                    break;
                }
            }
        }
    }

    fn sendMessage(self: *Self) void {
        if (std.mem.len(self.current_input) == 0) return;

        // Add user message to history
        const user_msg = ChatMessage{
            .role = .user,
            .content = self.wasm_app.allocator.dupe(u8, std.mem.span(self.current_input)) catch return,
            .timestamp = std.time.timestamp(),
        };
        self.chat_history.append(user_msg) catch return;

        // Clear input
        self.clearInput();

        // Set AI typing indicator
        self.is_ai_typing = true;

        // TODO: In a real implementation, this would make an HTTP request to the AI API
        // For now, we'll simulate a response
        self.simulateAIResponse();

        self.logToConsole("💬 Message sent to AI");
    }

    fn simulateAIResponse(self: *Self) void {
        // Simulate AI response after a delay
        // In a real implementation, this would be an async HTTP request
        const responses = [_][]const u8{
            "I'd be happy to help you with that! Could you provide more details about what you're working on?",
            "That's a great question! Let me break down the solution for you step by step.",
            "I see what you're trying to do. Here's how I would approach this problem:",
            "Based on your question, I think you might be looking for information about best practices in this area.",
        };

        const random_response = responses[@as(usize, @intCast(std.time.timestamp())) % responses.len];

        const ai_msg = ChatMessage{
            .role = .assistant,
            .content = self.wasm_app.allocator.dupe(u8, random_response) catch return,
            .timestamp = std.time.timestamp(),
        };
        self.chat_history.append(ai_msg) catch return;

        self.is_ai_typing = false;
        self.logToConsole("🤖 AI response received");
    }

    fn handleQuickAction(self: *Self, action: []const u8) void {
        const prompts = std.StringHashMap([]const u8).init(self.wasm_app.allocator);
        defer prompts.deinit();

        // Set up quick action prompts
        const action_prompts = [_]struct { key: []const u8, value: []const u8 }{
            .{ .key = "explain", .value = "Please explain this code and how it works:" },
            .{ .key = "debug", .value = "I'm having trouble with this code. Can you help me debug it?" },
            .{ .key = "optimize", .value = "How can I optimize this code for better performance?" },
            .{ .key = "learn", .value = "I want to learn more about this programming concept:" },
            .{ .key = "refactor", .value = "How should I refactor this code to make it cleaner?" },
            .{ .key = "test", .value = "Can you help me write unit tests for this code?" },
        };

        for (action_prompts) |prompt| {
            if (std.mem.eql(u8, action, prompt.key)) {
                // Set the input to the quick action prompt
                @memset(self.current_input, 0);
                @memcpy(self.current_input[0..prompt.value.len], prompt.value);

                self.logToConsole("🔧 Quick action selected");
                break;
            }
        }
    }

    fn appendToInput(self: *Self, codepoint: u32) void {
        const len = std.mem.len(self.current_input);
        if (len < self.current_input.len - 4) {
            // Convert Unicode codepoint to UTF-8
            var utf8_bytes: [4]u8 = undefined;
            const utf8_len = std.unicode.utf8Encode(codepoint, &utf8_bytes) catch return;

            @memcpy(self.current_input[len .. len + utf8_len], utf8_bytes[0..utf8_len]);
        }
    }

    fn clearInput(self: *Self) void {
        @memset(self.current_input, 0);
        self.logToConsole("🧹 Input cleared");
    }

    fn logToConsole(self: *Self, message: []const u8) void {
        _ = self;
        const c_message = gpa.allocator().dupeZ(u8, message) catch return;
        defer gpa.allocator().free(c_message);
        jaguar.platform.wasm.jaguar_wasm_log(c_message.ptr);
    }

    pub fn render(self: *Self) !void {
        try self.wasm_app.render(self.ui_context);
    }

    pub fn pollEvents(self: *Self) ![]jaguar.events.Event {
        return self.wasm_app.pollEvents();
    }
};

// WASM exports
export fn zeke_wasm_main() void {
    const allocator = gpa.allocator();

    zeke_app = ZekeApp.init(allocator) catch {
        jaguar.platform.wasm.jaguar_wasm_log("❌ Failed to initialize ZEKE");
        return;
    };

    // Register with JavaScript
    jaguar.platform.wasm.jaguar_wasm_set_app_instance(zeke_app.?.wasm_app);

    jaguar.platform.wasm.jaguar_wasm_log("🤖 ZEKE AI Chat initialized! Ready to assist with your coding needs.");
}

export fn zeke_wasm_frame() void {
    if (zeke_app == null) return;

    const app = zeke_app.?;

    // Poll and handle events
    const events = app.pollEvents() catch return;
    defer app.wasm_app.allocator.free(events);

    for (events) |event| {
        app.handleEvent(event);
    }

    // Render frame
    app.render() catch return;
}

export fn zeke_wasm_cleanup() void {
    if (zeke_app) |app| {
        app.deinit();
        gpa.allocator().destroy(app);
        zeke_app = null;
    }

    _ = gpa.deinit();
    jaguar.platform.wasm.jaguar_wasm_log("🤖 ZEKE cleanup complete");
}
