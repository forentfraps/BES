const std = @import("std");

pub fn build(b: *std.Build) void {
    const allocator = std.heap.page_allocator;
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
    // Determine the appropriate ASM file and NASM format based on the OS
    const asm_file = switch (target.result.os.tag) {
        .windows => "src\\comp_win.asm",
        .linux => "src/comp_lin.asm",
        else => {
            std.log.err("Unsupported operating system: {}", .{target.result.os.tag});
            return;
        },
    };

    const nasm_format = switch (target.result.os.tag) {
        .windows => "win64",
        .linux => "elf64",
        else => {
            std.log.err("Unsupported NASM format for OS: {}", .{target.result.os.tag});
            return;
        },
    };

    // Ensure the output directory exists
    const asm_output_dir = b.cache_root.join(allocator, &.{"asm_files"}) catch |e| {
        std.log.err("Could not join dir: {}\n", .{e});
        return;
    };

    const root_dir = std.fs.openDirAbsolute(b.build_root.path.?, .{}) catch |e| {
        std.log.err("Could not open the dir: {}\n", .{e});
        return;
    };
    root_dir.makeDir(asm_output_dir) catch |e| {
        if (e != error.PathAlreadyExists) {
            std.log.err("Could not make dir: {}\n", .{e});

            return;
        }
    };

    // Assemble the ASM file
    const asm_output_path = std.mem.concat(allocator, u8, &[_][]const u8{ asm_output_dir, "/comp.o" }) catch |e|
        {
        std.log.err("Could not concat paths: {}\n", .{e});
        return;
    };
    std.log.info("Building {s} for {s} into {s}\n", .{ asm_file, nasm_format, asm_output_path });
    const nasm_result = std.process.Child.run(.{
        .argv = &[_][]const u8{
            "nasm",
            "-f",
            nasm_format,
            asm_file,
            "-o",
            asm_output_path,
        },
        .allocator = std.heap.page_allocator,
    }) catch |e| {
        std.debug.print("Asm build failed -> {}\n", .{e});
        return;
    };

    // Add object file to the executable
    exe.addObjectFile(b.path(".zig-cache\\asm_files\\comp.o"));
    b.installArtifact(exe);

    std.log.info("NASM result: {}\n", .{nasm_result});
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
