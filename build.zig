const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var version = std.SemanticVersion.parse(std.mem.trim(u8, @embedFile(".version"), &std.ascii.whitespace)) catch unreachable;
    if (b.option([]const u8, "rev", "Git revision of ziptools")) |rev| {
        version.pre = "git";
        version.build = rev[0..@min(rev.len, 7)];
    } else {
        if (b.findProgram(&.{ "git" }, &.{}) catch null) |git| {
            var c: u8 = 0;
            if (b.runAllowFail(&.{ git, "rev-parse", "HEAD", }, &c, .Ignore) catch null) |raw_rev| {
                version.pre = "git";
                version.build = std.mem.trim(u8, raw_rev, &std.ascii.whitespace)[0..7];
            }
        }
    }

    const options = b.addOptions();
    options.addOption(std.SemanticVersion, "version", version);

    const mod = b.createModule(.{
        .root_source_file = b.path("src/ziptools.zig"),
        .target = target,
        .optimize = optimize,
    });

    mod.addOptions("options", options);

    const exe = b.addExecutable(.{
        .name = "ziptools",
        .root_module = mod,
    });

    b.installArtifact(exe);
}
