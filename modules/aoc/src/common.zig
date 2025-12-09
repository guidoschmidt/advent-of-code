const std = @import("std");
const types = @import("types.zig");
const puzzle_input = @import("input.zig");
const stopwatch = @import("stopwatch.zig");

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

pub fn runPart(
    allocator: std.mem.Allocator,
    comptime part_fn: fn (allocator: Allocator) anyerror!void,
) !void {
    stopwatch.start();
    try part_fn(allocator);
    const time = stopwatch.stop();
    printTime(time);
}

pub fn runDay(
    allocator: std.mem.Allocator,
    comptime part1: fn (allocator: Allocator) anyerror!void,
    comptime part2: fn (allocator: Allocator) anyerror!void,
) !void {
    try runPart(allocator, part1);
    try runPart(allocator, part2);
}
