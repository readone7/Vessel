const std = @import("std");
const cmd_init = @import("cmd/init.zig");
const cmd_deploy = @import("cmd/deploy.zig");
const cmd_push = @import("cmd/push.zig");
const cmd_ps = @import("cmd/ps.zig");
const cmd_docs = @import("cmd/docs.zig");
const cmd_logs = @import("cmd/logs.zig");
const cmd_rollback = @import("cmd/rollback.zig");
const cmd_doctor = @import("cmd/doctor.zig");
const cmd_diff = @import("cmd/diff.zig");
const cmd_repair = @import("cmd/repair.zig");

pub fn runInit(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_init.run(allocator, args);
}

pub fn runDeploy(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_deploy.run(allocator, args);
}

pub fn runPush(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_push.run(allocator, args);
}

pub fn runLogs(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_logs.run(allocator, args);
}

pub fn runDocs(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_docs.run(allocator, args);
}

pub fn runPs(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_ps.run(allocator, args);
}

pub fn runRollback(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_rollback.run(allocator, args);
}

pub fn runDoctor(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_doctor.run(allocator, args);
}

pub fn runDiff(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_diff.run(allocator, args);
}

pub fn runRepair(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try cmd_repair.run(allocator, args);
}

