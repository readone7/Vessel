const std = @import("std");

pub const WireVersion = struct {
    major: u16,
    minor: u16,
};

pub const current: WireVersion = .{ .major = 0, .minor = 1 };

pub fn isCompatible(node: WireVersion) bool {
    return node.major == current.major and node.minor <= current.minor;
}

test "compatibility allows n-1 minor in same major" {
    try std.testing.expect(isCompatible(.{ .major = 0, .minor = 0 }));
}

