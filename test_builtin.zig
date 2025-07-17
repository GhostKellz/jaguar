const std = @import("std");

pub fn main() void {
    std.debug.print("OS: {}\n", .{@tagName(std.builtin.cpu.arch)});
}
