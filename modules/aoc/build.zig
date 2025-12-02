const std = @import("std");
const input = @import("src/input.zig");
const types = @import("src/types.zig");
const utils = @import("src/utils.zig");

pub fn createTemplate(allocator: std.mem.Allocator, year: types.Year, day: types.Day) ![]const u8 {
    var template_str = utils.getTemplate();
    const day_str = try std.fmt.allocPrint(allocator, "{d}", .{day});
    defer allocator.free(day_str);
    const year_str = try std.fmt.allocPrint(allocator, "{d}", .{year});
    defer allocator.free(year_str);
    template_str = try std.mem.replaceOwned(u8, allocator, template_str, "\"$DAY\"", day_str);
    template_str = try std.mem.replaceOwned(u8, allocator, template_str, "\"$YEAR\"", year_str);
    return template_str;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("aoc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_puzzlehelper = b.addExecutable(.{
        .name = "puzzle-input-helper",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/fetch-puzzle-input.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe_puzzlehelper);
}
