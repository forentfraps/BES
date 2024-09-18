const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "BES",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const nasm_result = std.process.Child.run(.{
        .argv = &[_][]const u8{
            "nasm",
            "-f",
            "win64",
            "src/comp.asm",
            "-o",
            ".zig-cache/asm_files/comp.o",
        },
        .allocator = std.heap.page_allocator,
    }) catch |e| {
        std.debug.print("Asm build failed -> {}\n", .{e});
        return;
    };

    // Log the output from the NASM command
    std.debug.print("NASM step result: {}\n", .{nasm_result});

    exe.addObjectFile(b.path(".zig-cache\\asm_files\\comp.o"));
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
