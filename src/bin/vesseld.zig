const vessel = @import("vessel");
const io = vessel.io;

pub fn main() !void {
    try io.stdoutPrint("vesseld {s} listening on 127.0.0.1:4317 (scaffold)\n", .{vessel.version.semver});
    try io.stdoutPrint("transport: ssh-tunneled HTTP+JSON (phase 1)\n", .{});
}

