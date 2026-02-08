const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 1;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("puzzle-01");
    var floor: i32 = 0;
    for (input) |c| {
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            else => unreachable,
        }
    }

    std.debug.print("Result: {d}\n", .{floor});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("puzzle-01");
    var floor: i32 = 0;
    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        if (floor == -1) break;
        const c = input[idx];
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            else => unreachable,
        }
    }

    std.debug.print("Result: {d}\n", .{idx});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
