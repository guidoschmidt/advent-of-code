const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = -1; // @TODO
const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
