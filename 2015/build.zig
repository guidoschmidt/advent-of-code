const std = @import("std");
const aoc = @import("aoc");

const YEAR = 2015;
var DAY: u5 = 1;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (b.args) |args| {
        DAY = std.fmt.parseInt(u5, args[0], 10) catch 1;
        std.debug.print("🎅🏼 Running day {d:0>2}\n", .{DAY});
        const exe = try aoc.setupDay(b, target, optimize, YEAR, DAY);
        aoc.runDay(b, exe);
    } else {
        const src_dir = try std.fs.cwd().openDir("src/", .{
            .no_follow = true,
            .iterate = true,
            .access_sub_paths = false,
        });
        var it = src_dir.iterate();
        while (try it.next()) |f| {
            if (f.name[0] == '.') continue;
            const name = std.fs.path.stem(f.name);
            const day = try std.fmt.parseInt(aoc.types.Day, name[3..], 10);
            std.debug.print("🎅🏼 Building day {d:0>2}\n", .{day});
            _ = try aoc.setupDay(b, target, optimize, YEAR, day);
        }
    }
}
