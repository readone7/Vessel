const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const toml_dep = b.dependency("toml", .{
        .target = target,
        .optimize = optimize,
    });
    const toml_mod = toml_dep.module("toml");

    const vessel_mod = b.addModule("vessel", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "toml", .module = toml_mod },
        },
    });

    const vessel = b.addExecutable(.{
        .name = "vessel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bin/vessel.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "vessel", .module = vessel_mod },
                .{ .name = "toml", .module = toml_mod },
            },
        }),
    });
    b.installArtifact(vessel);

    const vesseld = b.addExecutable(.{
        .name = "vesseld",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bin/vesseld.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "vessel", .module = vessel_mod },
                .{ .name = "toml", .module = toml_mod },
            },
        }),
    });
    b.installArtifact(vesseld);

    const vegistry = b.addExecutable(.{
        .name = "vegistry",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bin/vegistry.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "vessel", .module = vessel_mod },
                .{ .name = "toml", .module = toml_mod },
            },
        }),
    });
    b.installArtifact(vegistry);

    const run_step = b.step("run", "Run vessel CLI");
    const run_cmd = b.addRunArtifact(vessel);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    run_step.dependOn(&run_cmd.step);

    const test_lib = b.addTest(.{ .root_module = vessel_mod });
    const test_vessel = b.addTest(.{ .root_module = vessel.root_module });
    const test_vesseld = b.addTest(.{ .root_module = vesseld.root_module });
    const test_vegistry = b.addTest(.{ .root_module = vegistry.root_module });

    const run_test_lib = b.addRunArtifact(test_lib);
    const run_test_vessel = b.addRunArtifact(test_vessel);
    const run_test_vesseld = b.addRunArtifact(test_vesseld);
    const run_test_vegistry = b.addRunArtifact(test_vegistry);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_test_lib.step);
    test_step.dependOn(&run_test_vessel.step);
    test_step.dependOn(&run_test_vesseld.step);
    test_step.dependOn(&run_test_vegistry.step);
}
