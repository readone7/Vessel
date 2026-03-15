const std = @import("std");
const docs = @import("../docs.zig");
const io = @import("../io.zig");

pub fn run(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) return error.MissingDocsSubcommand;
    if (std.mem.eql(u8, args[0], "lint")) {
        try docs.lint(allocator);
        try io.stdoutPrint("docs lint passed\n", .{});
        return;
    }
    return error.UnknownDocsSubcommand;
}

