const std = @import("std");
const jaguar = @import("jaguar");

pub fn main() !void {
    std.debug.print("🐆 Jaguar GUI Framework - Demo\n", .{});

    // Create and run a desktop application
    var app = try jaguar.App.init(.{ 
        .title = "Jaguar Demo", 
        .width = 800, 
        .height = 600 
    });
    defer app.deinit();

    std.debug.print("Starting Jaguar desktop app...\n", .{});
    
    // For now just print that we're running
    // TODO: Implement actual UI loop once we have windowing
    try jaguar.bufferedPrint();
    
    // Demo: create some widgets using the high-level API
    const text_widget = jaguar.widgets.text("Hello, Jaguar! 🐆");
    const button_widget = jaguar.widgets.button("Click me!", null);
    const input_widget = jaguar.widgets.input("Type something...");
    
    std.debug.print("Created widgets:\n", .{});
    std.debug.print("  Text: {s}\n", .{text_widget.content});
    std.debug.print("  Button: {s}\n", .{button_widget.content});
    std.debug.print("  Input placeholder: {s}\n", .{input_widget.data.input.placeholder});
    
    // For now, we'll skip the actual event loop since we don't have windowing yet
    // try app.run();
}

// Example callback function
fn on_button_click(ctx: *jaguar.Context) void {
    ctx.notify("Button was clicked!");
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
