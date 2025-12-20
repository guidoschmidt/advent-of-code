const std = @import("std");
const aoc = @import("aoc");

const YEAR: u12 = 2025;
const DAY: u5 = 1;

const Allocator = std.mem.Allocator;
const log = std.log;

fn unifiedSolution() anyerror!void {}

fn part1(allocator: Allocator) anyerror!void {
    _ = allocator;
    var row_it = std.mem.tokenizeSequence(u8, @embedFile("puzzle-01"), "\n");
    const max = 100;
    var i: u32 = 0;
    var dial: i32 = 50;
    var result: u32 = 0;
    while (row_it.next()) |row| : (i += 1) {
        // std.debug.print("{d}\n", .{dial});
        const sign: i32 = if (row[0] == 'L') -1 else 1;
        const number = try std.fmt.parseInt(i32, row[1..], 10);
        dial += sign * number;
        dial = @mod(dial, max);
        if (dial == 0) result += 1;
    }
    std.debug.print("\nResult: {d}\n", .{result});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    var row_it = std.mem.tokenizeSequence(u8, @embedFile("puzzle-01"), "\n");
    const max = 100;
    var dial: i32 = 50;
    var result: u32 = 0;
    while (row_it.next()) |row| {
        const sign: i32 = if (row[0] == 'L') -1 else 1;
        const number = try std.fmt.parseInt(i32, row[1..], 10);
        var change = sign * number;
        while (change != 0) : (change += -1 * sign) {
            dial += sign;
            dial = @mod(dial, max);
            if (dial == 0) result += 1;
        }
    }
    std.debug.print("\nResult: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
