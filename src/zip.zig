const std = @import("std");
const utils = @import("utils.zig");

fn printHelp(stdout: *std.io.Writer, is_subcommand: bool) !void {
    try stdout.print(
        \\Usage: {s} [options...] OUT files...
        \\
        \\Options:
        \\  --help  Prints usage and options
        \\
    , .{
        if (is_subcommand) "ziptool zip" else "zip",
    });
}

pub fn run(alloc: std.mem.Allocator, args: *std.process.ArgIterator, stdout: *std.Io.Writer, stderr: *std.Io.Writer, is_subcommand: bool) !struct { bool, bool } {
    var list = std.ArrayListUnmanaged([]const u8){};
    defer list.deinit(alloc);

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            try printHelp(stdout, is_subcommand);
            return .{ true, false };
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

    var central_headers = std.ArrayListUnmanaged(std.zip.CentralDirectoryFileHeader){};
    defer central_headers.deinit(alloc);

    var output = try utils.createFile(list.items[0], .{});
    defer output.close();

    var offset: usize = 0;

    for (list.items[1..]) |item| {
        try stdout.print("Adding: {s}\n", .{item});

        const source = try utils.readFile(alloc, item);
        defer alloc.free(source);

        const crc = std.hash.Crc32.hash(source);

        var local_header = std.zip.LocalFileHeader{
            .signature = std.zip.local_file_header_sig,
            .version_needed_to_extract = 20,
            .flags = .{ .encrypted = false, ._ = 0 },
            .compression_method = .store,
            .last_modification_time = 0,
            .last_modification_date = 0,
            .crc32 = crc,
            .compressed_size = @intCast(source.len),
            .uncompressed_size = @intCast(source.len),
            .filename_len = @intCast(item.len),
            .extra_len = 0,
        };

        _ = try output.writeAll(std.mem.asBytes(&local_header));
        _ = try output.writeAll(item);
        _ = try output.writeAll(source);

        const local_offset = offset;
        offset += @sizeOf(std.zip.LocalFileHeader) + item.len + source.len;

        try central_headers.append(alloc, .{
            .signature = std.zip.central_file_header_sig,
            .version_made_by = 20,
            .version_needed_to_extract = local_header.version_needed_to_extract,
            .flags = local_header.flags,
            .compression_method = local_header.compression_method,
            .last_modification_time = local_header.last_modification_time,
            .last_modification_date = local_header.last_modification_date,
            .crc32 = local_header.crc32,
            .compressed_size = local_header.compressed_size,
            .uncompressed_size = local_header.uncompressed_size,
            .filename_len = local_header.filename_len,
            .extra_len = 0,
            .comment_len = 0,
            .disk_number = 0,
            .internal_file_attributes = 0,
            .external_file_attributes = 0,
            .local_file_header_offset = @intCast(local_offset),
        });
    }

    const cd_start = offset;
    for (central_headers.items, 0..) |ch, i| {
        const item = list.items[i + 1];

        try output.writeAll(std.mem.asBytes(&ch));
        try output.writeAll(item);
        offset += @sizeOf(std.zip.CentralDirectoryFileHeader) + item.len;
    }

    const cd_size = offset - cd_start;

    var end = std.zip.EndRecord{
        .signature = std.zip.end_record_sig,
        .disk_number = 0,
        .central_directory_disk_number = 0,
        .record_count_disk = @intCast(list.items.len - 1),
        .record_count_total = @intCast(list.items.len - 1),
        .central_directory_size = @intCast(cd_size),
        .central_directory_offset = @intCast(cd_start),
        .comment_len = 0,
    };

    _ = try output.writeAll(std.mem.asBytes(&end));
    return .{ true, true };
}
