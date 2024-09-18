const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build the executable
    const exe = b.addExecutable(.{
        .name = "BES",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Run NASM to generate the .o file
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

    std.debug.print("NASM step result: {}\n", .{nasm_result});

    // Add object file to the executable
    exe.addObjectFile(b.path(".zig-cache\\asm_files\\comp.o"));
    b.installArtifact(exe);

    // Step to run the executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create the test executable
    const test_exe = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
    });

    // Add the object file to the test
    test_exe.addObjectFile(b.path(".zig-cache\\asm_files\\comp.o"));
    const run_test = b.addRunArtifact(test_exe);

    // Create a step to run the tests
    const test_step = b.step("test", "Run tests on assembly code");
    test_step.dependOn(&run_test.step);

    // Ensure the run command depends on both the executable and the test

    // Step to run the app
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
