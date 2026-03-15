const std = @import("std");

pub const version = @import("vessel/version.zig");
pub const cli = @import("vessel/cli.zig");
pub const config = @import("vessel/config.zig");
pub const orchestrator = @import("vessel/orchestrator.zig");
pub const transport = @import("vessel/transport.zig");
pub const io = @import("vessel/io.zig");
pub const docker = @import("vessel/docker.zig");
pub const ingress = @import("vessel/ingress.zig");
pub const health = @import("vessel/health.zig");
pub const state = @import("vessel/state.zig");
pub const protocol = @import("vessel/protocol.zig");
pub const networking = @import("vessel/networking.zig");
pub const scheduler = @import("vessel/scheduler.zig");
pub const docs = @import("vessel/docs.zig");
pub const logging = @import("vessel/logging.zig");

test "public API loads" {
    try std.testing.expect(version.semver.len > 0);
}
