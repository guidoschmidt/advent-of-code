const std = @import("std");
const puzzle_input = @import("./input.zig");
const stopwatch = @import("./stopwatch.zig");

const Allocator = std.mem.Allocator;

pub fn printPart1() void {
    std.debug.print("\n########## Part 1 ##########", .{});
}

pub fn printPart2() void {
    std.debug.print("\n########## Part 2 ##########", .{});
}

pub fn printTime(time: u64) void {
    const ns = time;
    const us: f64 = @floatFromInt(time / std.time.ns_per_us);
    const ms: f64 = @floatFromInt(time / std.time.ns_per_ms);
    std.debug.print("\n— ⏲ Running time: {d:3} ms / {d:3} μs / {d} ns\n", .{ ms, us, ns });
}

pub const PuzzleInput = enum { EXAMPLE, PUZZLE };

pub fn runPart(allocator: std.mem.Allocator, comptime year: u16, comptime day: u8, input_type: PuzzleInput, comptime part_fn: fn (allocator: Allocator, input: []const u8) anyerror!void) !void {
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
    try runPart(allocator, year, day, input_type, part1);
    try runPart(allocator, year, day, input_type, part2);
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
