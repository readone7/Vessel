const std = @import("std");

pub fn info(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[INFO] " ++ fmt ++ "\n", args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[WARN] " ++ fmt ++ "\n", args);
}

