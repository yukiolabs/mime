const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const main_tests = b.addTest("src/mime.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const gen_constants = b.addExecutable("constants", "build/generate.zig");

    const gen_step = b.step("gen", "Generate mime constants");
    const fmt = b.addFmt(&[_][]const u8{"src/"});
    gen_step.dependOn(&(gen_constants.run()).step);
    gen_step.dependOn(&fmt.step);
}
