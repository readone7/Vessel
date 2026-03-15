const std = @import("std");
const cfg = @import("../config.zig");
const health = @import("../health.zig");
const ingress = @import("../ingress.zig");
const state = @import("../state.zig");
const io = @import("../io.zig");
const push_cmd = @import("push.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    const deploy_cfg = try cfg.loadProjectConfig(allocator);
    defer deploy_cfg.deinit(allocator);

    const opts = DeployOptions.fromArgs(args);
    var plan = try state.DeployPlan.fromConfig(allocator, deploy_cfg, opts);
    defer plan.deinit(allocator);

    if (!opts.no_push) {
        try push_cmd.runImagePush(allocator, plan.image_ref, deploy_cfg.target_host);
    }

    const gate = health.defaultGateModel();
    try health.waitUntilHealthy(allocator, gate, plan.service_name);
    try ingress.ensureRoutes(allocator, plan.service_name, deploy_cfg.domain);
    const endpoint = try std.fmt.allocPrint(allocator, "https://{s}", .{deploy_cfg.domain});
    defer allocator.free(endpoint);
    try state.writeSingleServiceStatus(allocator, plan.service_name, "PendingVerification", endpoint);

    try io.stdoutPrint("deployed {s} to {s}\n", .{ plan.service_name, deploy_cfg.target_host });
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

