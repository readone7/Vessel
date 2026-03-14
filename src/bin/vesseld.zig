const std = @import("std");
const vessel = @import("vessel");

pub fn main() !void {
    const out = std.io.getStdOut().writer();
    try out.print("vesseld {s} listening on 127.0.0.1:4317 (scaffold)\n", .{vessel.version.semver});
    try out.writeAll("transport: ssh-tunneled HTTP+JSON (phase 1)\n");
}

