const std = @import("std");
const vessel = @import("vessel");

pub fn main() !void {
    const out = std.io.getStdOut().writer();
    try out.print("vegistry {s} (scaffold)\n", .{vessel.version.semver});
    try out.writeAll("registry-v2 subset for vessel push flow\n");
}

