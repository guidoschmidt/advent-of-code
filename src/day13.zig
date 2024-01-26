// Source: https://github.com/qsantos/advent-of-code/blob/master/2023/day12/src/main.rs#L6-L46
const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn part1(input: []const u8) anyerror!void {
    var row_it = std.mem.split(u8, input, "\n");

    const pattern_width = row_it.peek().?.len - 1;
    const pattern_height = (input.len / pattern_width) / 2 - 1;

    std.debug.print("\nPattern Sizes: {d} x {d}", .{ pattern_width, pattern_height });

    var pattern1 = std.ArrayList([]const u8).init(allocator);
    var pattern2 = std.ArrayList([]const u8).init(allocator);

    var pattern_id: usize = 0;
    while (row_it.next()) |row| {
        if (row.len == 0) {
            pattern_id = 1;
            // Skip empty line
            continue;
        }
        switch (pattern_id) {
            0 => try pattern1.append(row),
            1 => try pattern2.append(row),
            else => unreachable
        }
    }

    std.debug.print("\nPATTERN 1:", .{});
    for(0..pattern_height) |i| {
        std.debug.print("\n{s}", .{ pattern1.items[i] }); 
    }

    std.debug.print("\n:", .{});
    std.debug.print("\nPATTERN 2:", .{});
    for(0..pattern_height) |i| {
        std.debug.print("\n{s}", .{ pattern2.items[i] }); 
    }

    // @TODO find reflections
}

fn part2(input: []const u8) anyerror!void {
    _ = input;
}

pub fn main() !void {
    try common.runDay(allocator, 13, .TEST, part1, part2);
}
