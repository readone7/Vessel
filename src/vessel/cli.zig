const std = @import("std");
const version = @import("version.zig");
const orchestrator = @import("orchestrator.zig");

pub const Command = enum {
    init,
    deploy,
    push,
    logs,
    rollback,
    doctor,
    diff,
    repair,
    version,
    help,
};

pub fn parseCommand(arg: ?[]const u8) Command {
    const value = arg orelse return .help;
    if (std.mem.eql(u8, value, "init")) return .init;
    if (std.mem.eql(u8, value, "deploy")) return .deploy;
    if (std.mem.eql(u8, value, "push")) return .push;
    if (std.mem.eql(u8, value, "logs")) return .logs;
    if (std.mem.eql(u8, value, "rollback")) return .rollback;
    if (std.mem.eql(u8, value, "doctor")) return .doctor;
    if (std.mem.eql(u8, value, "diff")) return .diff;
    if (std.mem.eql(u8, value, "repair")) return .repair;
    if (std.mem.eql(u8, value, "version")) return .version;
    return .help;
}

pub fn run(allocator: std.mem.Allocator) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const cmd = parseCommand(if (args.len > 1) args[1] else null);
    switch (cmd) {
        .init => try orchestrator.runInit(allocator, args[2..]),
        .deploy => try orchestrator.runDeploy(allocator, args[2..]),
        .push => try orchestrator.runPush(allocator, args[2..]),
        .logs => try orchestrator.runLogs(allocator, args[2..]),
        .rollback => try orchestrator.runRollback(allocator, args[2..]),
        .doctor => try orchestrator.runDoctor(allocator, args[2..]),
        .diff => try orchestrator.runDiff(allocator, args[2..]),
        .repair => try orchestrator.runRepair(allocator, args[2..]),
        .version => try printVersion(),
        .help => try printHelp(),
    }
}

fn printVersion() !void {
    const out = std.io.getStdOut().writer();
    try out.print("vessel {s}\n", .{version.semver});
}

fn printHelp() !void {
    const out = std.io.getStdOut().writer();
    try out.print(
        \\vessel commands:
        \\  init <user@host>           Bootstrap a machine with vesseld
        \\  deploy [--no-push]         Deploy from compose.yaml and vessel.toml
        \\  push <image> <user@host>   Push image with vegistry tunnel flow
        \\  logs <service>             Stream service logs
        \\  rollback [revision]        Roll back to previous revision
        \\  doctor                     Run diagnostics
        \\  diff                       Compare desired vs actual state
        \\  repair                     Run guided remediations
        \\  version                    Show vessel version
        \\
    , .{});
}

test "parse command" {
    try std.testing.expectEqual(Command.init, parseCommand("init"));
    try std.testing.expectEqual(Command.help, parseCommand("unknown"));
}

