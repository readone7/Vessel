const std = @import("std");
const cfg = @import("config.zig");

pub const DeployPlan = struct {
    service_name: []const u8,
    image_ref: []const u8,

    pub fn fromConfig(allocator: std.mem.Allocator, project: cfg.ProjectConfig, opts: anytype) !DeployPlan {
        _ = opts;
        return .{
            .service_name = try allocator.dupe(u8, project.project_name),
            .image_ref = try allocator.dupe(u8, project.image),
        };
    }

    pub fn deinit(self: DeployPlan, allocator: std.mem.Allocator) void {
        allocator.free(self.service_name);
        allocator.free(self.image_ref);
    }
};

