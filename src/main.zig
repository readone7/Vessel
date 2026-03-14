const std = @import("std");
const vessel = @import("vessel");

pub fn main() !void {
    try vessel.cli.run(std.heap.page_allocator);
}
