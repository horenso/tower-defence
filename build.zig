const std = @import("std");

pub fn build(b: *std.Build) void {
    // const game_lib = b.addSharedLibrary(.{
    //     .name = "game",
    //     .root_source_file =
    //     .target = b.host,
    // });

    const exe = b.addExecutable(.{
        .name = "tower-defence",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
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
