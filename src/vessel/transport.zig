const std = @import("std");
const io = @import("io.zig");

pub fn bootstrapMachine(allocator: std.mem.Allocator, target: []const u8) !void {
    try io.stdoutPrint("bootstrapping {s}\n", .{target});
    try run(allocator, &.{ "ssh", target, "echo vessel bootstrap check" });
    try io.stdoutPrint("bootstrap scaffold complete (install/start vesseld)\n", .{});
}

pub fn run(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) return error.ExternalCommandFailed;
        },
        else => return error.ExternalCommandFailed,
    }
}

pub fn sshTunnel(allocator: std.mem.Allocator, target: []const u8, local_port: u16, remote_port: u16) !void {
    var local_buf: [16]u8 = undefined;
    var remote_buf: [16]u8 = undefined;
    const local = try std.fmt.bufPrint(&local_buf, "{d}", .{local_port});
    const remote = try std.fmt.bufPrint(&remote_buf, "{d}", .{remote_port});
    const mapping = try std.fmt.allocPrint(allocator, "{s}:127.0.0.1:{s}", .{ local, remote });
    defer allocator.free(mapping);
    try run(allocator, &.{ "ssh", "-L", mapping, target, "true" });
}

