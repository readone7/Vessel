const std = @import("std");

pub const PlacementDecision = struct {
    service: []const u8,
    machine: []const u8,
};

pub fn placeReplicas(allocator: std.mem.Allocator, service: []const u8, replicas: usize, machines: []const []const u8) ![]PlacementDecision {
    if (machines.len == 0) return error.NoMachines;

    const out = try allocator.alloc(PlacementDecision, replicas);
    for (out, 0..) |*item, idx| {
        item.* = .{
            .service = service,
            .machine = machines[idx % machines.len],
        };
    }
    return out;
}

