// Source: https://github.com/qsantos/advent-of-code/blob/master/2023/day12/src/main.rs#L6-L46
const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Pattern = struct {
    data: []const u8,
};

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.split(u8, input, "\n");
    var pattern_list = std.ArrayList(Pattern).init(allocator);

    var current_pattern_data = std.ArrayList(u8).init(allocator);
    while(row_it.next()) |row| {
        if (row.len == 0) {
            // @TODO next pattern
            try pattern_list.append(Pattern {
                .data = try allocator.dupe(u8, current_pattern_data.items)
            });
            current_pattern_data.clearAndFree();
            continue;
        }
        try current_pattern_data.appendSlice(row);
        try current_pattern_data.append('\n');
    }

    std.debug.print("\n{d} Pattern", .{ pattern_list.items.len });
    for(pattern_list.items) |pattern| {
        std.debug.print("\n\n{s}", .{ pattern.data });
    }
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try common.runDay(allocator, 13, .TEST, part1, part2);
}
