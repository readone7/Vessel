const std = @import("std");
const health = @import("../health.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try health.runDoctor(allocator);
}

