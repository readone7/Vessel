const std = @import("std");

pub const Runner = struct {
    ctx: *anyopaque,
    runFn: *const fn (ctx: *anyopaque, argv: []const []const u8) anyerror!void,

    pub fn run(self: *Runner, argv: []const []const u8) !void {
        return self.runFn(self.ctx, argv);
    }
};

pub const ProcessRunner = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ProcessRunner {
        return .{ .allocator = allocator };
    }

    pub fn asRunner(self: *ProcessRunner) Runner {
        return .{
            .ctx = self,
            .runFn = runImpl,
        };
    }

    fn runImpl(ctx: *anyopaque, argv: []const []const u8) !void {
        const self: *ProcessRunner = @ptrCast(@alignCast(ctx));
        var child = std.process.Child.init(argv, self.allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        const term = try child.spawnAndWait();
        switch (term) {
            .Exited => |code| if (code != 0) return error.ExternalCommandFailed,
            else => return error.ExternalCommandFailed,
        }
    }
};

pub const MockRunner = struct {
    allocator: std.mem.Allocator,
    calls: std.ArrayList([]u8) = .empty,

    pub fn init(allocator: std.mem.Allocator) MockRunner {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MockRunner) void {
        for (self.calls.items) |line| self.allocator.free(line);
        self.calls.deinit(self.allocator);
    }

    pub fn asRunner(self: *MockRunner) Runner {
        return .{
            .ctx = self,
            .runFn = runImpl,
        };
    }

    fn runImpl(ctx: *anyopaque, argv: []const []const u8) !void {
        const self: *MockRunner = @ptrCast(@alignCast(ctx));
        const line = try std.mem.join(self.allocator, " ", argv);
        try self.calls.append(self.allocator, line);
    }
};

test "mock runner captures commands" {
    var rec = MockRunner.init(std.testing.allocator);
    defer rec.deinit();
    var runner = rec.asRunner();
    try runner.run(&.{ "echo", "hello" });
    try std.testing.expect(rec.calls.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, rec.calls.items[0], "echo hello"));
}

