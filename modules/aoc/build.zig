const std = @import("std");
const input = @import("src/input.zig");
pub const types = @import("src/types.zig");
const utils = @import("src/utils.zig");

pub fn createTemplate(allocator: std.mem.Allocator, day: types.Day) ![]const u8 {
    var template_str = utils.getTemplate();
    std.debug.print("{any}\n", .{@TypeOf(template_str)});
    const search = "\"$DAY\"";
    const day_str = try std.fmt.allocPrint(allocator, "{d}", .{day});
    defer allocator.free(day_str);
    template_str = try std.mem.replaceOwned(u8, allocator, template_str, search, day_str);
    std.debug.print("{s}\n", .{template_str});
    // while (std.mem.indexOf(
    //     u8,
    //     template_str,
    // )) |found| {
    //     var output = try allocator.alloc(u8, search.len);
    // }
    //     std.debug.print("{any}: ", .{found});
    //     const found_slice = template_str[found .. found + "\"$DAY\"".len];
    //     std.debug.print("{s}\n", .{found_slice});
    //     break;
    //     // found_slice = day_str;
    // }
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
