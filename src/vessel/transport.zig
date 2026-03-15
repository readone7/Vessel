const std = @import("std");
const io = @import("io.zig");
const runner_mod = @import("runner.zig");

pub fn bootstrapMachine(allocator: std.mem.Allocator, target: []const u8) !void {
    try io.stdoutPrint("bootstrapping {s}\n", .{target});
    try run(allocator, &.{ "ssh", target, "echo vessel bootstrap check" });
    try io.stdoutPrint("bootstrap scaffold complete (install/start vesseld)\n", .{});
}

pub fn run(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var process_runner = runner_mod.ProcessRunner.init(allocator);
    var runner = process_runner.asRunner();
    return runner.run(argv);
}

pub const SshTunnel = struct {
    child: std.process.Child,

    pub fn close(self: *SshTunnel) !void {
        _ = self.child.kill() catch |err| switch (err) {
            error.ProcessNotFound => return,
            else => return err,
        };
        _ = self.child.wait() catch |err| switch (err) {
            error.ProcessNotFound => return,
            else => return err,
        };
    }
};

pub fn openSshTunnel(allocator: std.mem.Allocator, target: []const u8, local_port: u16, remote_port: u16) !SshTunnel {
    const mapping = try std.fmt.allocPrint(allocator, "{d}:127.0.0.1:{d}", .{ local_port, remote_port });
    defer allocator.free(mapping);

    var child = std.process.Child.init(&.{
        "ssh",
        "-N",
        "-L",
        mapping,
        "-o",
        "ExitOnForwardFailure=yes",
        target,
    }, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Inherit;
    try child.spawn();

    return .{ .child = child };
}

pub fn ensureTunnelAlive(tunnel: *SshTunnel, retries: u8, delay_ms: u32) !void {
    var attempt: u8 = 0;
    while (attempt < retries) : (attempt += 1) {
        if (isTunnelAlive(tunnel)) return;
        std.Thread.sleep(@as(u64, delay_ms) * std.time.ns_per_ms);
    }
    return error.TunnelNotAlive;
}

fn isTunnelAlive(tunnel: *SshTunnel) bool {
    const pid = tunnel.child.id;
    std.posix.kill(pid, 0) catch |err| switch (err) {
        error.ProcessNotFound => return false,
        else => return false,
    };
    return true;
}

