const std = @import("std");

// Write buffer size for buffered I/O. Each print call that produces more
// formatted output than this will flush in multiple chunks automatically,
// so this controls write granularity, not a hard output limit.
const write_buf_size = 8192;

pub fn stdoutPrint(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [write_buf_size]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const out = &writer.interface;
    try out.print(fmt, args);
    try out.flush();
}

pub fn stderrPrint(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [write_buf_size]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buffer);
    const err = &writer.interface;
    try err.print(fmt, args);
    try err.flush();
}

