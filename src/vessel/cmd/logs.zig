const std = @import("std");
const io = @import("../io.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len < 1) return error.MissingService;
    try io.stdoutPrint("logs fan-out is scaffolded for service {s}\n", .{args[0]});
}

