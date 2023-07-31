const std = @import("std");

const Value = @import("./value.zig").Value;

pub fn main() !void {
    std.debug.print("Hello, Virtual Machine!\n", .{});
}

test "test flogvm" {
    _ = @import("./Value.zig");
}
