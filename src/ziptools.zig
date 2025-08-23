const std = @import("std");
const options = @import("options");
const builtin = @import("builtin");
const native_os = builtin.os.tag;
const zip = @import("zip.zig");
const unzip = @import("unzip.zig");

fn printHelp(writer: *std.Io.Writer) !void {
    try writer.print(
        \\Ziptools v{f}
        \\Usage: ziptools CMD [options...]
        \\
        \\Commands:
        \\  unzip - Uncompresses zip archive
        \\  zip   - Compresses zip archive
        \\
    , .{options.version});
}

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const gpa, const is_debug = gpa: {
        if (native_os == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const raw_stdout = std.fs.File.stdout();

    var buff_stdout = [_]u8{0} ** 1024;
    var stdout = raw_stdout.writer(&buff_stdout);
    defer stdout.end() catch {};

    const raw_stderr = std.fs.File.stderr();

    var buff_stderr = [_]u8{0} ** 1024;
    var stderr = raw_stderr.writer(&buff_stderr);
    defer stderr.end() catch {};

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();

    const argv0 = std.fs.path.basename(args.next() orelse unreachable);
    var is_valid = true;
    var should_exit = false;
    if (blk: {
        if (std.mem.eql(u8, argv0, "ziptools")) break :blk args.next();
        break :blk argv0;
    }) |cmd| {
        const is_subcommand = !std.mem.eql(u8, argv0, cmd);
        if (std.mem.eql(u8, cmd, "zip")) is_valid, should_exit = try zip.run(gpa, &args, &stdout.interface, &stderr.interface, is_subcommand) else if (std.mem.eql(u8, cmd, "unzip")) is_valid, should_exit = try unzip.run(gpa, &args, &stdout.interface, &stderr.interface, is_subcommand) else is_valid = false;
    } else {
        is_valid = false;
    }

    if (!should_exit) {
        try printHelp(&stdout.interface);
        if (!is_valid) {
            try stdout.end();
            try stderr.end();
            std.process.exit(1);
        }
    }
}
