const std = @import("std");
const transport = @import("../transport.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len < 1) return error.MissingTarget;
    const target = args[0];
    try transport.bootstrapMachine(allocator, target);
}

