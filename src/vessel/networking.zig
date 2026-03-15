const std = @import("std");
const io = @import("io.zig");

pub fn joinNode(machine: []const u8) !void {
    try io.stdoutPrint("network scaffold join: {s}\n", .{machine});
}

pub fn ensureMesh() !void {
    try io.stdoutPrint("wireguard mesh scaffold\n", .{});
}

