const std = @import("std");

const FLOG_COMPILER_NAME: []const u8 = "flogc";
const FLOG_VM_NAME: []const u8 = "flogvm";

const FLOG_COMPILER_MAIN_PATH: []const u8 = "compiler/main.zig";
const FLOG_VM_MAIN_PATH: []const u8 = "runtime/main.zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    build_compiler(b, target, optimize);
    build_runtime(b, target, optimize);

    const compiler_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = FLOG_COMPILER_MAIN_PATH },
        .target = target,
        .optimize = optimize,
    });
    const run_compiler_unit_tests = b.addRunArtifact(compiler_unit_tests);

    const runtime_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = FLOG_VM_MAIN_PATH },
        .target = target,
        .optimize = optimize,
    });
    const run_runtime_unit_tests = b.addRunArtifact(runtime_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_compiler_unit_tests.step);
    test_step.dependOn(&run_runtime_unit_tests.step);
}

fn build_compiler(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) void {
    const exe = b.addExecutable(.{
        .name = FLOG_COMPILER_NAME,
        .root_source_file = .{ .path = FLOG_COMPILER_MAIN_PATH },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(FLOG_COMPILER_NAME, "Run the " ++ FLOG_COMPILER_NAME);
    run_step.dependOn(&run_cmd.step);
}

fn build_runtime(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) void {
    const exe = b.addExecutable(.{
        .name = FLOG_VM_NAME,
        .root_source_file = .{ .path = FLOG_VM_MAIN_PATH },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(FLOG_VM_NAME, "Run the " ++ FLOG_VM_NAME);
    run_step.dependOn(&run_cmd.step);
}
