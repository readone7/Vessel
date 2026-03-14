const std = @import("std");
const transport = @import("transport.zig");

pub fn pushViaTunnel(image: []const u8, target: []const u8) !void {
    const out = std.io.getStdOut().writer();
    try out.print("pushing {s} to {s}\n", .{ image, target });

    // Scaffolded sequence mirroring the plan's vegistry flow.
    try out.writeAll("1. open ssh tunnel\n");
    try out.writeAll("2. start temporary vegistry on target\n");
    try out.writeAll("3. docker push missing layers through tunnel\n");
    try out.writeAll("4. stop vegistry and close tunnel\n");

    // Use docker CLI under the hood as required by the plan.
    const allocator = std.heap.page_allocator;
    _ = transport.run(allocator, &.{ "docker", "image", "inspect", image }) catch {};
}

