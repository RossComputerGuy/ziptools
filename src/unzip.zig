const std = @import("std");
const utils = @import("utils.zig");

fn printHelp(stdout: *std.io.Writer, is_subcommand: bool) !void {
    try stdout.print(
        \\Usage: {s} [options...] IN files...
        \\
        \\Options:
        \\  --help  Prints usage and options
        \\
    , .{
        if (is_subcommand) "ziptool unzip" else "unzip",
    });
}

pub fn run(alloc: std.mem.Allocator, args: *std.process.ArgIterator, stdout: *std.Io.Writer, stderr: *std.Io.Writer, is_subcommand: bool) !struct { bool, bool } {
    var list = std.ArrayListUnmanaged([]const u8){};
    defer list.deinit(alloc);

    var dest = std.fs.cwd();
    var close_dest = false;
    defer if (close_dest) dest.close();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            try printHelp(stdout, is_subcommand);
            return .{ true, false };
        } else if (std.mem.eql(u8, arg, "-d")) {
            const value = args.next() orelse {
                try stderr.print("Argument \"{s}\" missing value\n", .{arg});
                return .{ false, false };
            };

            dest = if (std.fs.path.isAbsolute(value)) try std.fs.openDirAbsolute(value, .{}) else try std.fs.cwd().openDir(value, .{});

            close_dest = true;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            try stderr.print("Invalid argument: {s}\n", .{arg});
            return .{ false, false };
        } else {
            try list.append(alloc, arg);
        }
    }

    if (list.items.len == 0) {
        try printHelp(stdout, is_subcommand);
        return .{ false, false };
    }

    var input = try utils.openFile(list.items[0], .{});
    defer input.close();

    var buff = [_]u8{0} ** 1024;
    var input_reader = input.reader(&buff);

    var iter = try std.zip.Iterator.init(&input_reader);
    var filename_buf: [std.fs.max_path_bytes]u8 = undefined;
    while (try iter.next()) |entry| {
        const filename = filename_buf[0..entry.filename_len];
        try input_reader.seekTo(entry.header_zip_offset + @sizeOf(std.zip.CentralDirectoryFileHeader));
        try input_reader.interface.readSliceAll(filename);

        const should_extract = blk: {
            for (list.items[1..]) |item| {
                if (std.mem.eql(u8, filename, item)) break :blk true;
            }
            break :blk list.items.len == 1;
        };

        if (should_extract) {
            try stdout.print("Extracting: {s}\n", .{filename});
            try entry.extract(&input_reader, .{}, &filename_buf, dest);
        }
    }
    return .{ true, true };
}
