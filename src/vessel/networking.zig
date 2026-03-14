const std = @import("std");

pub fn joinNode(machine: []const u8) !void {
    const out = std.io.getStdOut().writer();
    try out.print("network scaffold join: {s}\n", .{machine});
}

pub fn ensureMesh() !void {
    const out = std.io.getStdOut().writer();
    try out.writeAll("wireguard mesh scaffold\n");
}

