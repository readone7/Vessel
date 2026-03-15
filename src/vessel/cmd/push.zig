const std = @import("std");
const docker = @import("../docker.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len < 2) return error.MissingPushArgs;
    try docker.pushViaTunnel(allocator, args[0], args[1]);
}

pub fn runImagePush(allocator: std.mem.Allocator, image: []const u8, target: []const u8) !void {
    try docker.pushViaTunnel(allocator, image, target);
}

