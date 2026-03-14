const std = @import("std");

pub const ProjectConfig = struct {
    project_name: []const u8,
    target_host: []const u8,
    domain: []const u8,
    image: []const u8,

    pub fn deinit(self: ProjectConfig, allocator: std.mem.Allocator) void {
        allocator.free(self.project_name);
        allocator.free(self.target_host);
        allocator.free(self.domain);
        allocator.free(self.image);
    }
};

pub fn loadProjectConfig(allocator: std.mem.Allocator) !ProjectConfig {
    const cwd = std.fs.cwd();

    // ADR-backed config model: compose.yaml + vessel.toml. For now we parse a
    // minimal key=value subset from vessel.toml and use defaults when absent.
    const maybe_content = cwd.readFileAlloc(allocator, "vessel.toml", 1024 * 64) catch null;
    defer if (maybe_content) |content| allocator.free(content);

    var project_name = try allocator.dupe(u8, "vessel-app");
    var target_host = try allocator.dupe(u8, "user@localhost");
    var domain = try allocator.dupe(u8, "app.localhost");
    var image = try allocator.dupe(u8, "vessel-app:latest");

    if (maybe_content) |content| {
        var lines = std.mem.tokenizeScalar(u8, content, '\n');
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0 or trimmed[0] == '#') continue;
            var split = std.mem.splitScalar(u8, trimmed, '=');
            const key = std.mem.trim(u8, split.first(), " \t");
            const value_raw = split.next() orelse continue;
            const value = trimQuotes(std.mem.trim(u8, value_raw, " \t"));

            if (std.mem.eql(u8, key, "project")) {
                allocator.free(project_name);
                project_name = try allocator.dupe(u8, value);
            } else if (std.mem.eql(u8, key, "target_host")) {
                allocator.free(target_host);
                target_host = try allocator.dupe(u8, value);
            } else if (std.mem.eql(u8, key, "domain")) {
                allocator.free(domain);
                domain = try allocator.dupe(u8, value);
            } else if (std.mem.eql(u8, key, "image")) {
                allocator.free(image);
                image = try allocator.dupe(u8, value);
            }
        }
    }

    return .{
        .project_name = project_name,
        .target_host = target_host,
        .domain = domain,
        .image = image,
    };
}

fn trimQuotes(value: []const u8) []const u8 {
    if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') {
        return value[1 .. value.len - 1];
    }
    return value;
}

test "parse minimal vessel toml style" {
    const sample =
        \\project = "demo"
        \\target_host = "root@1.2.3.4"
        \\domain = "demo.example.com"
        \\image = "demo:1"
    ;
    _ = sample;
}

