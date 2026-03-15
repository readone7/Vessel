const std = @import("std");
const transport = @import("transport.zig");
const io = @import("io.zig");
const runner_mod = @import("runner.zig");

pub fn pushViaTunnel(allocator: std.mem.Allocator, image: []const u8, target: []const u8) !void {
    const cfg = try PushConfig.load(allocator);
    var process_runner = runner_mod.ProcessRunner.init(allocator);
    var runner = process_runner.asRunner();
    return pushViaTunnelWithRunner(allocator, image, target, cfg, &runner);
}

fn pushViaTunnelWithRunner(
    allocator: std.mem.Allocator,
    image: []const u8,
    target: []const u8,
    cfg: PushConfig,
    runner: *runner_mod.Runner,
) !void {
    try io.stdoutPrint("pushing {s} to {s}\n", .{ image, target });

    // Scaffolded sequence mirroring the plan's vegistry flow.
    try io.stdoutPrint("1. open ssh tunnel\n", .{});
    try io.stdoutPrint("2. start temporary vegistry on target\n", .{});
    try io.stdoutPrint("3. docker push missing layers through tunnel\n", .{});
    try io.stdoutPrint("4. stop vegistry and close tunnel\n", .{});

    const remote_port: u16 = 5000;
    const selection = try openTunnelWithRetry(allocator, target, remote_port, cfg);
    const local_port = selection.local_port;
    var tunnel = selection.tunnel;
    defer tunnel.close() catch {};
    try transport.ensureTunnelAlive(&tunnel, cfg.tunnel_alive_retries, cfg.tunnel_alive_delay_ms);

    // Ensure any stale container is removed first.
    _ = runner.run(&.{ "ssh", target, "docker", "rm", "-f", "vegistry-temp" }) catch {};
    runner.run(&.{
        "ssh",
        target,
        "docker",
        "run",
        "-d",
        "--rm",
        "--name",
        "vegistry-temp",
        "-p",
        "127.0.0.1:5000:5000",
        "ghcr.io/psviderski/unregistry:latest",
    }) catch return error.RemoteVegistryStartFailed;
    defer _ = runner.run(&.{ "ssh", target, "docker", "rm", "-f", "vegistry-temp" }) catch {};
    waitForTunnelEndpoint(allocator, local_port, cfg.endpoint_ready_retries, cfg.endpoint_ready_delay_ms) catch {
        return error.TunnelEndpointNotReady;
    };

    const remote_ref = try std.fmt.allocPrint(allocator, "localhost:{d}/{s}", .{ local_port, image });
    defer allocator.free(remote_ref);
    try runPushCommandSequence(runner, image, remote_ref);

    try io.stdoutPrint("push complete: {s}\n", .{remote_ref});
}

fn runPushCommandSequence(runner: *runner_mod.Runner, image: []const u8, remote_ref: []const u8) !void {
    runner.run(&.{ "docker", "image", "inspect", image }) catch return error.LocalImageNotFound;
    runner.run(&.{ "docker", "tag", image, remote_ref }) catch return error.DockerTagFailed;
    runner.run(&.{ "docker", "push", remote_ref }) catch return error.DockerPushFailed;
}

const TunnelSelection = struct {
    tunnel: transport.SshTunnel,
    local_port: u16,
};

const PushConfig = struct {
    local_port_min: u16 = 55000,
    local_port_max: u16 = 58999,
    port_probe_attempts: u8 = 20,
    tunnel_alive_retries: u8 = 8,
    tunnel_alive_delay_ms: u16 = 80,
    endpoint_ready_retries: u8 = 20,
    endpoint_ready_delay_ms: u16 = 100,

    fn load(allocator: std.mem.Allocator) !PushConfig {
        var out: PushConfig = .{};
        out.local_port_min = try readEnvU16(allocator, "VESSEL_PUSH_PORT_MIN", out.local_port_min);
        out.local_port_max = try readEnvU16(allocator, "VESSEL_PUSH_PORT_MAX", out.local_port_max);
        out.port_probe_attempts = try readEnvU8(allocator, "VESSEL_PUSH_PORT_PROBE_ATTEMPTS", out.port_probe_attempts);
        out.tunnel_alive_retries = try readEnvU8(allocator, "VESSEL_PUSH_TUNNEL_RETRIES", out.tunnel_alive_retries);
        out.tunnel_alive_delay_ms = try readEnvU16(allocator, "VESSEL_PUSH_TUNNEL_DELAY_MS", out.tunnel_alive_delay_ms);
        out.endpoint_ready_retries = try readEnvU8(allocator, "VESSEL_PUSH_READY_RETRIES", out.endpoint_ready_retries);
        out.endpoint_ready_delay_ms = try readEnvU16(allocator, "VESSEL_PUSH_READY_DELAY_MS", out.endpoint_ready_delay_ms);

        if (out.local_port_min >= out.local_port_max) return error.InvalidPortRange;
        return out;
    }
};

fn openTunnelWithRetry(allocator: std.mem.Allocator, target: []const u8, remote_port: u16, cfg: PushConfig) !TunnelSelection {
    const range = cfg.local_port_max - cfg.local_port_min + 1;
    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
    const seed_offset = prng.random().intRangeAtMost(u16, 0, range - 1);

    var attempt: u8 = 0;
    while (attempt < cfg.port_probe_attempts) : (attempt += 1) {
        const offset = @as(u16, @intCast((seed_offset + attempt) % range));
        const port = cfg.local_port_min + offset;

        const tunnel = transport.openSshTunnel(allocator, target, port, remote_port) catch {
            continue;
        };
        return .{
            .tunnel = tunnel,
            .local_port = port,
        };
    }
    return error.SshTunnelOpenFailed;
}

fn waitForTunnelEndpoint(allocator: std.mem.Allocator, local_port: u16, retries: u8, delay_ms: u16) !void {
    var attempt: u8 = 0;
    while (attempt < retries) : (attempt += 1) {
        const stream = std.net.tcpConnectToHost(allocator, "127.0.0.1", local_port) catch {
            std.Thread.sleep(@as(u64, delay_ms) * std.time.ns_per_ms);
            continue;
        };
        stream.close();
        return;
    }
    return error.TunnelEndpointNotReady;
}

fn readEnvU16(allocator: std.mem.Allocator, name: []const u8, default: u16) !u16 {
    const value = std.process.getEnvVarOwned(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return default,
        else => return err,
    };
    defer allocator.free(value);
    return std.fmt.parseInt(u16, value, 10) catch default;
}

fn readEnvU8(allocator: std.mem.Allocator, name: []const u8, default: u8) !u8 {
    const value = std.process.getEnvVarOwned(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return default,
        else => return err,
    };
    defer allocator.free(value);
    return std.fmt.parseInt(u8, value, 10) catch default;
}

test "push command sequence construction" {
    var rec = runner_mod.MockRunner.init(std.testing.allocator);
    defer rec.deinit();
    var runner = rec.asRunner();
    try runPushCommandSequence(&runner, "myapp:1", "localhost:55000/myapp:1");
    try std.testing.expect(rec.calls.items.len == 3);
    try std.testing.expect(std.mem.eql(u8, rec.calls.items[0], "docker image inspect myapp:1"));
    try std.testing.expect(std.mem.eql(u8, rec.calls.items[1], "docker tag myapp:1 localhost:55000/myapp:1"));
    try std.testing.expect(std.mem.eql(u8, rec.calls.items[2], "docker push localhost:55000/myapp:1"));
}

