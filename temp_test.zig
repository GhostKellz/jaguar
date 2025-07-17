const std = @import("std"); pub fn main() void { std.debug.print("{}
", .{@typeName(@TypeOf(std.builtin))}); }
