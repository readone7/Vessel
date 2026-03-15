const std = @import("std");
const cfg = @import("config.zig");
const io = @import("io.zig");

pub const DeployPlan = struct {
    service_name: []const u8,
    image_ref: []const u8,

    pub fn fromConfig(allocator: std.mem.Allocator, project: cfg.ProjectConfig, opts: anytype) !DeployPlan {
        _ = opts;
        return .{
            .service_name = try allocator.dupe(u8, project.project_name),
            .image_ref = try allocator.dupe(u8, project.image),
        };
    }

    pub fn deinit(self: DeployPlan, allocator: std.mem.Allocator) void {
        allocator.free(self.service_name);
        allocator.free(self.image_ref);
    }
};

pub const ServiceStatus = struct {
    name: []const u8,
    state: []const u8,
    endpoint: []const u8,
};

const state_dir = ".vessel";
const state_file = ".vessel/state.json";
const state_version: u32 = 1;

const ParsedStateDocument = struct {
    version: u32,
    services: []ServiceStatus,
};

const WriteStateDocument = struct {
    version: u32,
    services: []const ServiceStatus,
};

pub fn writeSingleServiceStatus(allocator: std.mem.Allocator, name: []const u8, service_state: []const u8, endpoint: []const u8) !void {
    const existing = try loadServiceStatuses(allocator);
    defer freeServiceStatuses(allocator, existing);

    var list: std.ArrayList(ServiceStatus) = .empty;
    defer {
        for (list.items) |item| {
            allocator.free(item.name);
            allocator.free(item.state);
            allocator.free(item.endpoint);
        }
        list.deinit(allocator);
    }

    var found = false;
    for (existing) |item| {
        const updated = std.mem.eql(u8, item.name, name);
        try list.append(allocator, .{
            .name = try allocator.dupe(u8, item.name),
            .state = try allocator.dupe(u8, if (updated) service_state else item.state),
            .endpoint = try allocator.dupe(u8, if (updated) endpoint else item.endpoint),
        });
        if (updated) found = true;
    }

    if (!found) {
        try list.append(allocator, .{
            .name = try allocator.dupe(u8, name),
            .state = try allocator.dupe(u8, service_state),
            .endpoint = try allocator.dupe(u8, endpoint),
        });
    }

    try writeStateFile(allocator, list.items);
}

fn writeStateFile(allocator: std.mem.Allocator, statuses: []const ServiceStatus) !void {
    _ = allocator;
    const cwd = std.fs.cwd();
    try cwd.makePath(state_dir);

    const file = try cwd.createFile(state_file, .{ .truncate = true });
    defer file.close();

    // 32 KB covers ~200 services at typical field lengths. Buffered writer
    // flushes to disk when full, so this is write granularity not a hard limit.
    var buffer: [32768]u8 = undefined;
    var writer = file.writer(&buffer);
    const out = &writer.interface;
    const doc = WriteStateDocument{
        .version = state_version,
        .services = statuses,
    };
    try std.json.Stringify.value(doc, .{}, out);
    try out.print("\n", .{});
    try out.flush();
}

pub fn loadServiceStatuses(allocator: std.mem.Allocator) ![]ServiceStatus {
    const cwd = std.fs.cwd();
    const content = cwd.readFileAlloc(allocator, state_file, 1024 * 128) catch |err| switch (err) {
        error.FileNotFound => return allocator.alloc(ServiceStatus, 0),
        else => return err,
    };
    defer allocator.free(content);

    var parsed = std.json.parseFromSlice(ParsedStateDocument, allocator, content, .{}) catch {
        return error.InvalidStateFile;
    };
    defer parsed.deinit();

    if (parsed.value.version != state_version) return error.UnsupportedStateVersion;

    var list: std.ArrayList(ServiceStatus) = .empty;
    defer list.deinit(allocator);
    for (parsed.value.services) |item| {
        try list.append(allocator, .{
            .name = try allocator.dupe(u8, item.name),
            .state = try allocator.dupe(u8, item.state),
            .endpoint = try allocator.dupe(u8, item.endpoint),
        });
    }

    return list.toOwnedSlice(allocator);
}

pub fn freeServiceStatuses(allocator: std.mem.Allocator, statuses: []ServiceStatus) void {
    for (statuses) |item| {
        allocator.free(item.name);
        allocator.free(item.state);
        allocator.free(item.endpoint);
    }
    allocator.free(statuses);
}

pub fn printServiceStatuses(statuses: []const ServiceStatus) !void {
    try io.stdoutPrint("NAME            STATE      ENDPOINT\n", .{});
    if (statuses.len == 0) {
        try io.stdoutPrint("(no services)\n", .{});
        return;
    }

    for (statuses) |item| {
        try io.stdoutPrint("{s}\t{s}\t{s}\n", .{ item.name, item.state, item.endpoint });
    }
}

test "load returns empty slice when state file does not exist" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Use a temp directory so the test never reads a real .vessel/state.json
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const prev = std.fs.cwd();
    try std.posix.fchdir(tmp.dir.fd);
    defer std.posix.fchdir(prev.fd) catch {};

    const statuses = try loadServiceStatuses(allocator);
    try std.testing.expectEqual(@as(usize, 0), statuses.len);
}

test "round-trip write and load" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const prev = std.fs.cwd();
    try std.posix.fchdir(tmp.dir.fd);
    defer std.posix.fchdir(prev.fd) catch {};

    try writeSingleServiceStatus(allocator, "web", "Running", "https://example.com");
    try writeSingleServiceStatus(allocator, "api", "Starting", "https://api.example.com");
    // Upsert existing entry
    try writeSingleServiceStatus(allocator, "web", "Healthy", "https://example.com");

    const statuses = try loadServiceStatuses(allocator);
    try std.testing.expectEqual(@as(usize, 2), statuses.len);
    try std.testing.expectEqualStrings("web", statuses[0].name);
    try std.testing.expectEqualStrings("Healthy", statuses[0].state);
    try std.testing.expectEqualStrings("api", statuses[1].name);
}

