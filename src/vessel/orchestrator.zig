const std = @import("std");
const cfg = @import("config.zig");
const transport = @import("transport.zig");
const docker = @import("docker.zig");
const ingress = @import("ingress.zig");
const health = @import("health.zig");
const state = @import("state.zig");
const io = @import("io.zig");

pub fn runInit(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len < 1) return error.MissingTarget;
    const target = args[0];
    try transport.bootstrapMachine(allocator, target);
}

pub fn runDeploy(allocator: std.mem.Allocator, args: []const []const u8) !void {
    const deploy_cfg = try cfg.loadProjectConfig(allocator);
    defer deploy_cfg.deinit(allocator);

    const opts = DeployOptions.fromArgs(args);
    var plan = try state.DeployPlan.fromConfig(allocator, deploy_cfg, opts);
    defer plan.deinit(allocator);

    if (!opts.no_push) {
        try runPush(allocator, &.{ plan.image_ref, deploy_cfg.target_host });
    }

    const gate = health.defaultGateModel();
    try health.waitUntilHealthy(allocator, gate, plan.service_name);
    try ingress.ensureRoutes(allocator, plan.service_name, deploy_cfg.domain);

    try io.stdoutPrint("deployed {s} to {s}\n", .{ plan.service_name, deploy_cfg.target_host });
}

pub fn runPush(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len < 2) return error.MissingPushArgs;
    try docker.pushViaTunnel(args[0], args[1]);
}

pub fn runLogs(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len < 1) return error.MissingService;
    try io.stdoutPrint("logs fan-out is scaffolded for service {s}\n", .{args[0]});
}

pub fn runRollback(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    try io.stdoutPrint("rollback scaffold: uses rolling path + health gates\n", .{});
}

pub fn runDoctor(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try health.runDoctor(allocator);
}

pub fn runDiff(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    try io.stdoutPrint("diff scaffold: desired vs actual drift view\n", .{});
}

pub fn runRepair(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    try io.stdoutPrint("repair scaffold: run guided remediations\n", .{});
}

const DeployOptions = struct {
    no_push: bool = false,

    fn fromArgs(args: []const []const u8) DeployOptions {
        var out: DeployOptions = .{};
        for (args) |arg| {
            if (std.mem.eql(u8, arg, "--no-push")) out.no_push = true;
        }
        return out;
    }
};

