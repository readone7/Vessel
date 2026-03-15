const std = @import("std");

pub fn stdoutPrint(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const out = &writer.interface;
    try out.print(fmt, args);
    try out.flush();
}

pub fn stderrPrint(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [2048]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buffer);
    const err = &writer.interface;
    try err.print(fmt, args);
    try err.flush();
}

