const std = @import("std");

pub fn ensureRoutes(allocator: std.mem.Allocator, service: []const u8, domain: []const u8) !void {
    _ = allocator;
    const out = std.io.getStdOut().writer();
    try out.print("caddy route ensure: {s} -> https://{s}\n", .{ service, domain });
}

