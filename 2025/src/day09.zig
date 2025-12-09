const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 9;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("example-09");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("example-09");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    // try aoc.runPart(allocator, part2);
}
