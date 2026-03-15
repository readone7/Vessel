const io = @import("io.zig");

pub fn info(comptime fmt: []const u8, args: anytype) void {
    io.stdoutPrint("[INFO] " ++ fmt ++ "\n", args) catch {};
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    io.stderrPrint("[WARN] " ++ fmt ++ "\n", args) catch {};
}

