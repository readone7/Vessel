const std = @import("std");
const io = @import("io.zig");

pub const Quadrant = enum {
    tutorials,
    how_to,
    reference,
    explanation,
};

pub fn isDiataxisEnabled() bool {
    return true;
}

pub fn quadrants() []const Quadrant {
    return &.{ .tutorials, .how_to, .reference, .explanation };
}

pub fn quadrantName(q: Quadrant) []const u8 {
    return switch (q) {
        .tutorials => "tutorials",
        .how_to => "how-to",
        .reference => "reference",
        .explanation => "explanation",
    };
}

pub fn isKnownQuadrant(name: []const u8) bool {
    return std.mem.eql(u8, name, "tutorials") or
        std.mem.eql(u8, name, "how-to") or
        std.mem.eql(u8, name, "reference") or
        std.mem.eql(u8, name, "explanation");
}

pub fn lint(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const cwd = std.fs.cwd();
    var docs_dir = cwd.openDir("docs", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return error.MissingDocsDirectory,
        else => return err,
    };
    defer docs_dir.close();

    for (quadrants()) |q| {
        const q_name = quadrantName(q);
        try validateQuadrantDir(docs_dir, q_name);
    }

    var it = docs_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .directory) continue;
        if (!isAllowedTopLevel(entry.name)) {
            try io.stderrPrint("unknown docs top-level directory: {s}\n", .{entry.name});
            return error.UnknownDocsTopLevelDirectory;
        }
    }
}

fn validateQuadrantDir(docs_dir: std.fs.Dir, q_name: []const u8) !void {
    var q_dir = docs_dir.openDir(q_name, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            try io.stderrPrint("missing docs quadrant directory: docs/{s}\n", .{q_name});
            return error.MissingDocsQuadrant;
        },
        else => return err,
    };
    defer q_dir.close();

    var has_markdown = false;
    var it = q_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.endsWith(u8, entry.name, ".md")) {
            has_markdown = true;
            break;
        }
    }

    if (!has_markdown) {
        try io.stderrPrint("docs quadrant has no markdown files: docs/{s}\n", .{q_name});
        return error.EmptyDocsQuadrant;
    }
}

fn isAllowedTopLevel(name: []const u8) bool {
    return isKnownQuadrant(name) or std.mem.eql(u8, name, "architecture");
}

test "diataxis utilities" {
    try std.testing.expect(isDiataxisEnabled());
    try std.testing.expect(quadrants().len == 4);
    try std.testing.expect(isKnownQuadrant("reference"));
    try std.testing.expect(!isKnownQuadrant("random"));
}

