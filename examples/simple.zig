//! 🐆 Jaguar Simple Example - Basic usage demonstration
const std = @import("std");
const jaguar = @import("jaguar");

pub fn main() !void {
    std.debug.print("🐆 Jaguar Simple Example\n", .{});
    
    // Initialize the theme system
    const theme = jaguar.theme.Theme.DARK;
    std.debug.print("Using theme: {s}\n", .{theme.name});
    
    // Create some widgets using the high-level API
    var widgets = [_]jaguar.widgets.Widget{
        jaguar.widgets.text("Welcome to Jaguar! 🚀"),
        jaguar.widgets.button("Get Started", null),
        jaguar.widgets.input("Enter your name..."),
        jaguar.widgets.slider(0.0, 100.0, 50.0),
        jaguar.widgets.checkbox(false),
    };
    
    std.debug.print("Created {} widgets:\n", .{widgets.len});
    for (widgets, 0..) |widget, i| {
        std.debug.print("  {}: {} - {s}\n", .{ i, widget.type, widget.content });
    }
    
    // Demonstrate layout
    jaguar.widgets.Layout.column(&widgets);
    std.debug.print("Applied column layout\n", .{});
    
    // Show widget positions after layout
    for (widgets, 0..) |widget, i| {
        std.debug.print("  Widget {}: x={}, y={}, w={}, h={}\n", .{ 
            i, widget.rect.x, widget.rect.y, widget.rect.width, widget.rect.height 
        });
    }
    
    std.debug.print("Example completed successfully! ✨\n", .{});
}
