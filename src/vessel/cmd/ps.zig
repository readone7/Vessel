const std = @import("std");
const state = @import("../state.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    const statuses = try state.loadServiceStatuses(allocator);
    defer state.freeServiceStatuses(allocator, statuses);
    try state.printServiceStatuses(statuses);
}

