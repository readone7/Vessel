const std = @import("std");
const io = @import("io.zig");

pub fn ensureRoutes(allocator: std.mem.Allocator, service: []const u8, domain: []const u8) !void {
    _ = allocator;
    try io.stdoutPrint("caddy route ensure: {s} -> https://{s}\n", .{ service, domain });
}

