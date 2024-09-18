const std = @import("std");

extern fn Encrypt16Bytes([*]u8, *u128, [*]u8) c_int;
extern fn Decrypt16Bytes([*]u8, *u128, [*]u8) c_int;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var input_file_path: []const u8 = "";
    var output_file_path: []const u8 = "output.enc";
    var args_it = try std.process.argsWithAllocator(allocator);
    var mode: u8 = 0;
    defer args_it.deinit();
    _ = args_it.skip(); // Skip the program name
    //
    var input_specified = false;
    var arg_presence = false;

    while (args_it.next()) |arg| {
        arg_presence = true;
        if (std.mem.eql(u8, arg, "-i")) {
            if (args_it.next()) |input_arg| {
                input_file_path = input_arg;
                input_specified = true;
            } else {
                return error.InvalidInput;
            }
        } else if (std.mem.eql(u8, arg, "-o")) {
            if (args_it.next()) |output_arg| {
                output_file_path = output_arg;
            } else {
                return error.InvalidOutput;
            }
        } else if (std.mem.eql(u8, arg, "-e")) {
            mode = 1;
        } else if (std.mem.eql(u8, arg, "-d")) {
            mode = 2;
        } else if (std.mem.eql(u8, arg, "-h")) {
            std.debug.print("-e to Encrypt\n-d to Decrypt\n-i to open a file\n-o to Specify the output file, the default is output.enc\n-h to display this menu\n", .{});
            return;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.InvalidArgument;
        }
    }
    if (arg_presence == false) {
        std.debug.print("-e to Encrypt\n-d to Decrypt\n-i to open a file\n-o to Specify the output file, the default is output.enc\n-h to display this menu\n", .{});
        return;
    }
    if (mode == 0) {
        std.debug.print("Please specify -e or -d for either encryption or decryption\n", .{});
        return;
    }
    if (input_specified == false) {
        std.debug.print("Please specify the -i input file you want to work with", .{});
    }

    // Open the input file
    var input_file = try std.fs.cwd().openFile(input_file_path, .{});
    defer input_file.close();
    const output_file = try std.fs.cwd().createFile(output_file_path, .{});
    defer output_file.close();
    var buffer: []u8 = undefined;
    var buffer_size: usize = undefined;
    defer allocator.free(buffer);

    // Get the file size
    const file_info = try input_file.stat();
    const file_size = file_info.size;

    var seed: u128 = 0xDEADBEEFCAFEBABE;
    //encrypt
    if (mode == 1) {

        // Allocate a buffer twice the size of the file
        buffer_size = file_size * 2;
        buffer = try allocator.alloc(u8, buffer_size);

        std.debug.print("Allocated buffer of size: {}\n", .{buffer_size});
        var input_buffer: [16]u8 align(16) = undefined;
        for (0..(file_size / 16)) |i| {
            _ = (try input_file.read(input_buffer[0..16][i * 16 .. (i + 1) * 16]));
            _ = Encrypt16Bytes(input_buffer[0..16].ptr, &seed, buffer[i * 32 ..].ptr);
        }
    } else if (mode == 2) {
        buffer_size = file_size / 2;
        buffer = try allocator.alloc(u8, buffer_size);
        var input_buffer: [32]u8 align(16) = undefined;
        for (0..(file_size / 32)) |i| {
            _ = (try input_file.read(input_buffer[0..32][i * 32 .. (i + 1) * 32]));
            _ = Decrypt16Bytes(input_buffer[0..].ptr, &seed, buffer[i * 16 ..].ptr);
        }
    }
    _ = try output_file.write(buffer[0..buffer_size]);

    return;
}

//test "simple test" {}
