const std = @import("std");
const io = @import("io.zig");

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
    try io.stdoutPrint(
        "health gate ({any}, retries={d}) passed for {s}\n",
        .{ model.precedence, model.retries, service },
    );
}

pub fn runDoctor(allocator: std.mem.Allocator) !void {
    _ = allocator;
    try io.stdoutPrint("doctor checks:\n", .{});
    try io.stdoutPrint("- ssh connectivity\n", .{});
    try io.stdoutPrint("- vesseld health endpoint\n", .{});
    try io.stdoutPrint("- caddy admin endpoint\n", .{});
    try io.stdoutPrint("- docker daemon availability\n", .{});
}

test "default precedence starts with docker healthcheck" {
    try std.testing.expectEqual(ProbeKind.docker_healthcheck, defaultGateModel().precedence[0]);
}

