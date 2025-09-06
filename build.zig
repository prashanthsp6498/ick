const std = @import("std");

var version: std.SemanticVersion = .{ .major = 0, .minor = 0, .patch = 0, .build = "debug" };

const BuildParams = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    b: *std.Build,
    exe_name: []const u8,

    pub fn new(self: BuildParams, exe_name: []const u8) @This() {
        return .{
            .target = self.target,
            .optimize = self.optimize,
            .b = self.b,
            .exe_name = exe_name,
        };
    }
};

fn get_version(b: *std.Build) std.SemanticVersion {
    const version_string = b.option([]const u8, "version-string", "Set the version of the build. Must be semantic");
    if (version_string) |semver_string| {
        return std.SemanticVersion.parse(semver_string) catch |err| {
            std.debug.panic("Expected -Dversion-string={s} to be a semantic version: {}", .{ semver_string, err });
        };
    }

    return version; // for now later change it to git tag
}

fn get_exe(params: BuildParams) struct { *std.Build.Module, *std.Build.Step.Compile } {
    const target = params.target;
    const optimize = params.optimize;
    const b = params.b;
    const exe_options = blk: {
        const exe_options = b.addOptions();
        exe_options.step.name = "ick exe options";
        exe_options.addOption(bool, "debug_build", optimize == .Debug);
        exe_options.addOption(std.SemanticVersion, "version", version);
        exe_options.addOption([]const u8, "version_string", b.fmt("{}", .{version}));

        break :blk exe_options.createModule();
    };

    const logger_module = b.addModule("tracy", .{
        .root_source_file = b.path("src/logger.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "exe_options", .module = exe_options },
        },
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "exe_options", .module = exe_options },
            .{ .name = "logger", .module = logger_module },
        },
    });

    const exe = b.addExecutable(.{
        .name = "ick",
        .root_module = exe_mod,
    });

    const vaxis = b.dependency("vaxis", .{ .target = target, .optimize = optimize });

    exe.root_module.addImport("vaxis", vaxis.module("vaxis"));

    return .{ exe_mod, exe };
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_params = BuildParams{
        .b = b,
        .optimize = optimize,
        .target = target,
        .exe_name = "ick",
    };

    version = get_version(b);
    const module = get_exe(build_params);
    b.installArtifact(module.@"1");

    const run_cmd = b.addRunArtifact(module.@"1");

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = module.@"0",
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const check_build_params = build_params.new("ick_check");
    const mod_lsp = get_exe(check_build_params);
    const check = b.step("check", "Check for lsp");
    check.dependOn(&mod_lsp.@"1".step);
}
