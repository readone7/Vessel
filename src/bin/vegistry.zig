const vessel = @import("vessel");
const io = vessel.io;

pub fn main() !void {
    try io.stdoutPrint("vegistry {s} (scaffold)\n", .{vessel.version.semver});
    try io.stdoutPrint("registry-v2 subset for vessel push flow\n", .{});
}

