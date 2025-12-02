const std = @import("std");
const aoc = @import("aoc");

const YEAR: u12 = "$YEAR";
const DAY: u5 = "$DAY";

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{@embedFile("puzzle")});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{@embedFile("puzzle")});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, DAY, .EXAMPLE, part1);
    try aoc.runPart(allocator, DAY, .EXAMPLE, part2);
}
