const std = @import("std");
const puzzle_input = @import("./puzzle_input.zig");
const stopwatch = @import("./stopwatch.zig");

const Allocator = std.mem.Allocator;

pub const clear = "\x1B[0m";
pub const red = "\x1B[31m";
pub const green = "\x1B[32m";
pub const yellow = "\x1B[33m";
pub const blue = "\x1B[34m";
pub const light_blue = "\x1B[36m";
pub const gray = "\x1B[37m";

pub fn printPart1() void {
    std.debug.print("\n########## Part 1 ##########", .{});
}

pub fn printPart2() void {
    std.debug.print("\n########## Part 2 ##########", .{});
}

pub fn printTime(time: u64) void {
    std.debug.print("\n— ⏲ Running time: {d:3} ms\n", .{ time });
}

pub const PuzzleInput = enum {
    EXAMPLE,
    PUZZLE
};

pub fn runDay(allocator: std.mem.Allocator, day: u8,
              input_type: PuzzleInput,
              comptime part1: fn(allocator: Allocator, input: []const u8) anyerror!void,
              comptime part2: fn(allocator: Allocator, input: []const u8) anyerror!void) !void {
    const input = switch(input_type) {
        .PUZZLE => try puzzle_input.getPuzzleInput(allocator, day),
        .EXAMPLE => try puzzle_input.getPuzzleTestInput(allocator, day),
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
