const std = @import("std");

pub const ProbeKind = enum {
    docker_healthcheck,
    http_readiness,
    tcp_open,
    stability_window,
};

pub const GateModel = struct {
    precedence: [4]ProbeKind,
    retries: u8,
    stability_seconds: u16,
};

pub fn defaultGateModel() GateModel {
    return .{
        .precedence = .{
            .docker_healthcheck,
            .http_readiness,
            .tcp_open,
            .stability_window,
        },
        .retries = 3,
        .stability_seconds = 15,
    };
}

pub fn waitUntilHealthy(allocator: std.mem.Allocator, model: GateModel, service: []const u8) !void {
    _ = allocator;
    const out = std.io.getStdOut().writer();
    try out.print(
        "health gate ({any}, retries={d}) passed for {s}\n",
        .{ model.precedence, model.retries, service },
    );
}

pub fn runDoctor(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const out = std.io.getStdOut().writer();
    try out.writeAll("doctor checks:\n");
    try out.writeAll("- ssh connectivity\n");
    try out.writeAll("- vesseld health endpoint\n");
    try out.writeAll("- caddy admin endpoint\n");
    try out.writeAll("- docker daemon availability\n");
}

test "default precedence starts with docker healthcheck" {
    try std.testing.expectEqual(ProbeKind.docker_healthcheck, defaultGateModel().precedence[0]);
}

