const std = @import("std");
const puzzle_input = @import("./puzzle_input.zig");
const stopwatch = @import("./stopwatch.zig");

pub fn printPart1() void {
    std.debug.print("\n########## Part 1 ##########", .{});
}

pub fn printPart2() void {
    std.debug.print("\n########## Part 2 ##########", .{});
}

pub fn printTime(time: u64) void {
    std.debug.print("\n— ⏲ Running time: {d:3} ms\n", .{ time });
}

pub fn runDay(allocator: std.mem.Allocator, day: u8,
              comptime part1: fn(input: []const u8) void,
              comptime part2: fn(input: []const u8) void) !void {
    const input = try puzzle_input.getPuzzleInput(allocator, day);

    printPart1();
    stopwatch.start();
    part1(input);
    const time_part1 = stopwatch.stop();
    printTime(time_part1);

    printPart2();
    stopwatch.start();
    part2(input);
    const time_part2 = stopwatch.stop();
    printTime(time_part2);
}
