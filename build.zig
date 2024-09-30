const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const game_lib = b.addSharedLibrary(.{
        .name = "game",
        .root_source_file = b.path("lib/game.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    game_lib.linkSystemLibrary("SDL2");
    game_lib.linkSystemLibrary("SDL2_image");
    game_lib.linkSystemLibrary("SDL2_ttf");
    game_lib.linkSystemLibrary("c");

    b.installArtifact(game_lib);

    const exe = b.addExecutable(.{
        .name = "game",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
