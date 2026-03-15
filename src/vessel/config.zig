const std = @import("std");
const toml = @import("toml");
const logging = @import("logging.zig");

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
    const maybe_content = cwd.readFileAlloc(allocator, "vessel.toml", 1024 * 64) catch null;
    defer if (maybe_content) |content| allocator.free(content);

    var project_name = try allocator.dupe(u8, "vessel-app");
    var target_host = try allocator.dupe(u8, "user@localhost");
    var domain = try allocator.dupe(u8, "app.localhost");
    var image = try allocator.dupe(u8, "vessel-app:latest");

    if (maybe_content) |content| {
        var structured_parser = toml.Parser(StructuredConfig).init(allocator);
        defer structured_parser.deinit();

        if (structured_parser.parseString(content)) |structured_result| {
            defer structured_result.deinit();
            const parsed = structured_result.value;
            if (parsed.project) |proj| {
                if (proj.name) |value| {
                    allocator.free(project_name);
                    project_name = try allocator.dupe(u8, value);
                }
            }
            if (parsed.deploy) |dep| {
                if (dep.image) |value| {
                    allocator.free(image);
                    image = try allocator.dupe(u8, value);
                }
                if (chooseFirst(dep.target_host, dep.target_hosts)) |value| {
                    allocator.free(target_host);
                    target_host = try allocator.dupe(u8, value);
                }
                if (chooseFirst(dep.domain, dep.domains)) |value| {
                    allocator.free(domain);
                    domain = try allocator.dupe(u8, value);
                }
            }
        } else |_| {
            logging.warn("vessel.toml: structured parse failed, trying flat key format", .{});
            var flat_parser = toml.Parser(FlatConfig).init(allocator);
            defer flat_parser.deinit();
            var flat_result = try flat_parser.parseString(content);
            defer flat_result.deinit();
            const parsed = flat_result.value;

            if (parsed.project) |value| {
                allocator.free(project_name);
                project_name = try allocator.dupe(u8, value);
            }
            if (parsed.image) |value| {
                allocator.free(image);
                image = try allocator.dupe(u8, value);
            }
            if (chooseFirst(parsed.target_host, parsed.target_hosts)) |value| {
                allocator.free(target_host);
                target_host = try allocator.dupe(u8, value);
            }
            if (chooseFirst(parsed.domain, parsed.domains)) |value| {
                allocator.free(domain);
                domain = try allocator.dupe(u8, value);
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

fn chooseFirst(single: ?[]const u8, many: ?[]const []const u8) ?[]const u8 {
    if (single) |value| return value;
    if (many) |slice| {
        if (slice.len > 0) return slice[0];
    }
    return null;
}

const ProjectSection = struct {
    name: ?[]const u8 = null,
};

const DeploySection = struct {
    image: ?[]const u8 = null,
    target_host: ?[]const u8 = null,
    target_hosts: ?[]const []const u8 = null,
    domain: ?[]const u8 = null,
    domains: ?[]const []const u8 = null,
};

const StructuredConfig = struct {
    project: ?ProjectSection = null,
    deploy: ?DeploySection = null,
};

const FlatConfig = struct {
    project: ?[]const u8 = null,
    image: ?[]const u8 = null,
    target_host: ?[]const u8 = null,
    target_hosts: ?[]const []const u8 = null,
    domain: ?[]const u8 = null,
    domains: ?[]const []const u8 = null,
};

test "parse minimal vessel toml style" {
    const sample =
        \\project = "demo"
        \\target_host = "root@1.2.3.4"
        \\domain = "demo.example.com"
        \\image = "demo:1"
    ;
    var parser = toml.Parser(FlatConfig).init(std.testing.allocator);
    defer parser.deinit();
    var parsed = try parser.parseString(sample);
    defer parsed.deinit();
    try std.testing.expect(std.mem.eql(u8, parsed.value.project.?, "demo"));
}

test "parse section keys and arrays" {
    const sample =
        \\[project]
        \\name = "demo"
        \\
        \\[deploy]
        \\target_hosts = ["root@1.2.3.4", "root@2.3.4.5"]
        \\domains = ["demo.example.com", "backup.example.com"]
        \\image = "demo:2"
    ;
    var parser = toml.Parser(StructuredConfig).init(std.testing.allocator);
    defer parser.deinit();
    var parsed = try parser.parseString(sample);
    defer parsed.deinit();

    const dep = parsed.value.deploy.?;
    try std.testing.expect(std.mem.eql(u8, chooseFirst(dep.target_host, dep.target_hosts).?, "root@1.2.3.4"));
    try std.testing.expect(std.mem.eql(u8, chooseFirst(dep.domain, dep.domains).?, "demo.example.com"));
}

