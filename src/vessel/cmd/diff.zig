const std = @import("std");
const io = @import("../io.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    try io.stdoutPrint("diff scaffold: desired vs actual drift view\n", .{});
}

