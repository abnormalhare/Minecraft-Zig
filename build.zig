const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Minecraft",
        .root_source_file = b.path("src/RubyDung.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ZSTBI //
    const zstbi = b.dependency("zstbi", .{});
    exe.root_module.addImport("zstbi", zstbi.module("root"));
    exe.linkLibrary(zstbi.artifact("zstbi"));

    // GLFW3 //
    const glfw3 = b.addTranslateC(.{
        .root_source_file = b.path("include/GLFW/glfw3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.root_module.addImport("glfw3", glfw3.createModule());

    if (target.result.os.tag == .windows) {
        // Billy gates
        // GLU //
        const glu = b.addTranslateC(.{
            .root_source_file = b.path("include/GL/glu.h"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        exe.root_module.addImport("glu", glu.createModule());

        exe.addLibraryPath(b.path("./lib/"));
        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("opengl32");
        exe.linkSystemLibrary("glu32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shlwapi");
    } else {
        // Linux, MacOS, BSD, etc.

        // GLU //
        exe.addSystemIncludePath(.{ .cwd_relative = "/usr/include/" });
        exe.linkSystemLibrary("GLU");
        exe.linkSystemLibrary("GL");

        exe.addLibraryPath(b.path("./lib/"));
        exe.linkSystemLibrary("glfw3");
    }

    exe.linkLibC();

    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/RubyDung.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
