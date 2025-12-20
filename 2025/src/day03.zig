const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;

const YEAR: u12 = 2025;
const DAY: u5 = 3;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input_embed = @embedFile("puzzle-03");
    var sum: u32 = 0;

    var reader: std.Io.Reader = .fixed(input_embed);
    while (try reader.takeDelimiter('\n')) |line| {
        var largest: u8 = 0;

        for (0..line.len) |i| {
            const start_digit = try std.fmt.charToDigit(line[i], 10);
            for (i + 1..line.len) |j| {
                const end_digit = try std.fmt.charToDigit(line[j], 10);
                const combination = start_digit * 10 + end_digit;
                if (combination > largest) largest = combination;
            }
        }
        sum += largest;
    }
    std.debug.print("Result: {d}\n", .{sum});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    var total_joltage: u128 = 0;

    const input = @embedFile("puzzle-03");
    var reader: std.Io.Reader = .fixed(input);

    const battery_count = 12;
    while (try reader.takeDelimiter('\n')) |line| {
        const contained_number = try findLargestContainedNumber(
            @TypeOf(total_joltage),
            line,
            battery_count,
        );
        total_joltage += contained_number;
    }

    std.debug.print("Result: {d}\n", .{total_joltage});
}

fn findLargestContainedNumber(comptime T: type, line: []const u8, battery_count: usize) !T {
    var largest_contained_number: T = 0;
    var start_idx: usize = 0;
    var search_space = line[start_idx .. line.len - (battery_count - 1)];
    var found_digit_count: usize = 0;
    for (0..battery_count) |e| {
        var max: u8 = try std.fmt.charToDigit(search_space[0], 10);
        var max_idx: usize = 0;
        for (search_space[0..], 0..) |c, i| {
            if (try std.fmt.charToDigit(c, 10) > max) {
                max = c - '0';
                max_idx = i;
            }
        }

        largest_contained_number += max * std.math.pow(T, 10, (battery_count - 1) - e);

        found_digit_count += 1;
        start_idx += max_idx + 1;
        const upper_bound = @min(
            line.len,
            @max(
                (line.len - (battery_count -| 1 -| found_digit_count)),
                start_idx + 1,
            ),
        );
        search_space = line[start_idx..upper_bound];
        // std.debug.print("   > max: {d} [{d}]\n", .{ max, max_idx });
    }
    return largest_contained_number;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}

test "example-part2" {
    try expect(987654321111 == try findLargestContainedNumber(u32, "987654321111111", 12));
    try expect(811111111119 == try findLargestContainedNumber(u32, "811111111111119", 12));
    try expect(434234234278 == try findLargestContainedNumber(u32, "234234234234278", 12));
    try expect(888911112111 == try findLargestContainedNumber(u32, "818181911112111", 12));

    try expect(919 == try findLargestContainedNumber(u32, "9119", 3));
    try expect(123 == try findLargestContainedNumber(u32, "111123", 3));
    try expect(923 == try findLargestContainedNumber(u32, "234789123", 3));
    try expect(11145 == try findLargestContainedNumber(u32, "1111145", 5));
    try expect(99919 == try findLargestContainedNumber(u32, "19191919", 5));

    try expect(99919 == try findLargestContainedNumber(u32, "19191919", 5));

    const input_example = @embedFile("example-03");
    var result: u128 = 0;
    var reader: std.Io.Reader = .fixed(input_example);
    while (try reader.takeDelimiter('\n')) |line| {
        const number = try findLargestContainedNumber(u32, line, 12);
        result += number;
    }
    try expect(result == 3121910778619);

    _ = try findLargestContainedNumber(u128, "2753445676625843555534776876555247667428557664243735457776754553427876646616644267454232337424744677", 12);
}
