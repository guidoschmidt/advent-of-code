const std = @import("std");
const puzzle_input = @import("./puzzle_input.zig");
const stopwatch = @import("./stopwatch.zig");

const Allocator = std.mem.Allocator;

pub fn printPart1() void {
    std.debug.print("\n########## Part 1 ##########", .{});
}

pub fn printPart2() void {
    std.debug.print("\n########## Part 2 ##########", .{});
}

pub fn printTime(time: u64) void {
    std.debug.print("\n— ⏲ Running time: {d:3} ms\n", .{time});
}

pub const PuzzleInput = enum { EXAMPLE, PUZZLE };

pub fn runPart(allocator: std.mem.Allocator, year: u16, day: u8, input_type: PuzzleInput, comptime part_fn: fn (allocator: Allocator, input: []const u8) anyerror!void) !void {
    const input = switch (input_type) {
        .PUZZLE => try puzzle_input.getPuzzleInput(allocator, day, year),
        .EXAMPLE => try puzzle_input.getExampleInput(allocator, day, year),
    };
    stopwatch.start();
    try part_fn(allocator, input);
    const time = stopwatch.stop();
    printTime(time);
}

pub fn runDay(allocator: std.mem.Allocator, year: u16, day: u8, input_type: PuzzleInput, comptime part1: fn (allocator: Allocator, input: []const u8) anyerror!void, comptime part2: fn (allocator: Allocator, input: []const u8) anyerror!void) !void {
    const input = switch (input_type) {
        .PUZZLE => try puzzle_input.getPuzzleInput(allocator, day, year),
        .EXAMPLE => try puzzle_input.getExampleInput(allocator, day, year),
    };

    printPart1();
    stopwatch.start();
    try part1(allocator, input);
    const time_part1 = stopwatch.stop();
    printTime(time_part1);

    printPart2();
    stopwatch.start();
    try part2(allocator, input);
    const time_part2 = stopwatch.stop();
    printTime(time_part2);
}

pub fn blockAskForNext() void {
    step: {
        const in = std.io.getStdIn();
        var buf = std.io.bufferedReader(in.reader());
        var r = buf.reader();
        std.debug.print("\n\nNext?... ", .{});
        var msg_buf: [4096]u8 = undefined;
        _ = r.readUntilDelimiterOrEof(&msg_buf, '\n') catch unreachable;
        break :step;
    }
}
