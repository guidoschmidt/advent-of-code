const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

fn hash(step: []const u8) u8 {
    var value: u32 = 0;
    for (step) |s| {
        value += @intCast(s);
        value *= 17;
        value = @mod(value, 256);
    }
    return @intCast(value);
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const cleaned_input = try std.mem.replaceOwned(u8, allocator, input, "\n", "");
    var steps_it = std.mem.tokenize(u8, cleaned_input, ",");
    var sum: u32 = 0;
    while(steps_it.next()) |step| {
        if (step.len == 0) break;
        const value = hash(step);
        std.debug.print("\n{s: >8} → {d: <3}", .{ step, value });
        sum += value;
    }
    std.debug.print("\n\nResult: {d}\n", .{ sum });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try aoc.runPart(allocator, 2023, 15, .PUZZLE, part1);
    try aoc.runPart(allocator, 2023, 15, .PUZZLE, part2);
}
