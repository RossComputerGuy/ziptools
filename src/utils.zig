const std = @import("std");

pub fn createFile(p: []const u8, flags: std.fs.File.CreateFlags) !std.fs.File {
    if (std.fs.path.isAbsolute(p)) {
        return std.fs.createFileAbsolute(p, flags);
    }

    return std.fs.cwd().createFile(p, flags);
}

pub fn openFile(p: []const u8, flags: std.fs.File.OpenFlags) !std.fs.File {
    if (std.fs.path.isAbsolute(p)) {
        return std.fs.openFileAbsolute(p, flags);
    }

    return std.fs.cwd().openFile(p, flags);
}

pub fn readFile(alloc: std.mem.Allocator, p: []const u8) ![]const u8 {
    var file = try openFile(p, .{});
    defer file.close();

    return try file.readToEndAlloc(alloc, std.math.maxInt(usize));
}
