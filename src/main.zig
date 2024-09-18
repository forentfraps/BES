pub const std = @import("std");

pub extern fn Encrypt16Bytes([*]align(16) const u8, *u128, [*]align(16) u8) c_int;
pub extern fn Decrypt16Bytes([*]align(16) const u8, *u128, [*]align(16) u8) c_int;

const expect = std.testing.expect;
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var input_file_path: []const u8 = "";
    var output_file_path: []const u8 = "output.enc";
    var seed: u128 = 0xDEADBEEFCAFEBABEEF;
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
        } else if (std.mem.eql(u8, arg, "-k")) {
            if (args_it.next()) |input_arg| {
                seed = try std.fmt.parseInt(u128, input_arg, 16);
            } else {
                return error.InvalidInput;
            }
        } else if (std.mem.eql(u8, arg, "-h")) {
            std.debug.print(
                \\-e to Encrypt
                \\-d to Decrypt
                \\-k [hex_string] 16 byte key in hex, the default is 0xDEADBEEFCAFEBABEEF
                \\-i [filepath] to open a file
                \\-o [filepath] to Specify the output file, the default is output.enc
                \\-h to display this menu
            , .{});
            return;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.InvalidArgument;
        }
    }
    if (arg_presence == false) {
        std.debug.print(
            \\-e to Encrypt
            \\-d to Decrypt
            \\-k [hex_string] 16 byte key in hex, the default is 0xDEADBEEFCAFEBABEEF
            \\-i [filepath] to open a file
            \\-o [filepath] to Specify the output file, the default is output.enc
            \\-h to display this menu
        , .{});
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
    var buffer: []align(16) u8 = undefined;
    var buffer_size: usize = undefined;
    defer allocator.free(buffer);

    // Get the file size
    const file_info = try input_file.stat();
    const file_size = file_info.size;

    //encrypt
    if (mode == 1) {

        // Allocate a buffer twice the size of the file
        const padding_len: usize = file_size % 16;

        if (padding_len > 0) {
            buffer_size = (file_size - padding_len + 16) * 2;
        } else {
            buffer_size = file_size * 2;
        }
        buffer = @as([]align(16) u8, @alignCast(try allocator.alloc(u8, buffer_size)));

        std.debug.print("Allocated buffer of size: {}\n", .{buffer_size});
        var input_buffer: [16]u8 align(16) = undefined;
        for (0..(file_size / 16)) |i| {
            _ = (try input_file.read(input_buffer[0..16]));
            _ = Encrypt16Bytes(input_buffer[0..16].ptr, &seed, @as([*]align(16) u8, @alignCast(buffer[i * 32 ..].ptr)));
        }
        if (padding_len > 0) {
            @memset(input_buffer[0..16], 0);
            _ = (try input_file.read(input_buffer[0..16]));
            _ = Encrypt16Bytes(input_buffer[0..16].ptr, &seed, @as([*]align(16) u8, @alignCast(buffer[buffer_size - 32 ..].ptr)));
        }
        // decrypt
    } else if (mode == 2) {
        buffer_size = file_size / 2;
        buffer = @as([]align(16) u8, @alignCast(try allocator.alloc(u8, buffer_size)));
        var input_buffer: [32]u8 align(16) = undefined;
        for (0..(file_size / 32)) |i| {
            _ = (try input_file.read(input_buffer[0..32]));
            _ = Decrypt16Bytes(input_buffer[0..].ptr, &seed, @as([*]align(16) u8, @alignCast(buffer[i * 16 ..].ptr)));
        }
    }
    _ = try output_file.write(buffer[0..buffer_size]);

    return;
}

test "asm_modules" {
    std.debug.print("Asm modules test\n", .{});

    const input_buffer: [16]u8 align(16) = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf };
    const expected_output: [32]u8 = [_]u8{
        0xF0, 0x00, 0x7E, 0x04, // Bytes 0 - 3
        0xE7, 0x00, 0xBC, 0x01, // Bytes 4 - 7
        0x2E, 0x01, 0xDB, 0x01, // Bytes 8 - 11
        0x9F, 0x00, 0xE2, 0x03, // Bytes 12 - 15
        0x37, 0x00, 0xB4, 0x00, // Bytes 16 - 19
        0xFF, 0x00, 0x75, 0x00, // Bytes 20 - 23
        0x01, 0x00, 0x47, 0x00, // Bytes 24 - 27
        0xCF, 0x01, 0x36, 0x01, // Bytes 28 - 31
    };
    var output_buffer: [32]u8 align(16) = undefined;
    var decrypt_buffer: [16]u8 align(16) = undefined;
    var seed: u128 = 0xDEADBEEF;

    std.debug.print("Test Encrypt\n", .{});
    try expect(Encrypt16Bytes(input_buffer[0..].ptr, &seed, output_buffer[0..].ptr) == 0);

    std.debug.print("Test Encrypt values\n", .{});
    try expect(std.mem.eql(u8, output_buffer[0..32], expected_output[0..32]));

    std.debug.print("Test Decrypt\n", .{});
    try expect(Decrypt16Bytes(output_buffer[0..].ptr, &seed, decrypt_buffer[0..].ptr) == 0);
    std.debug.print("Test Decrypt values\n", .{});
    try expect(std.mem.eql(u8, input_buffer[0..16], decrypt_buffer[0..16]));
    std.debug.print("Test Success\n", .{});
}
