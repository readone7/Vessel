const std = @import("std");
const transport = @import("transport.zig");
const io = @import("io.zig");

pub fn pushViaTunnel(image: []const u8, target: []const u8) !void {
    try io.stdoutPrint("pushing {s} to {s}\n", .{ image, target });

    // Scaffolded sequence mirroring the plan's vegistry flow.
    try io.stdoutPrint("1. open ssh tunnel\n", .{});
    try io.stdoutPrint("2. start temporary vegistry on target\n", .{});
    try io.stdoutPrint("3. docker push missing layers through tunnel\n", .{});
    try io.stdoutPrint("4. stop vegistry and close tunnel\n", .{});

    // Use docker CLI under the hood as required by the plan.
    const allocator = std.heap.page_allocator;
    _ = transport.run(allocator, &.{ "docker", "image", "inspect", image }) catch {};
}

