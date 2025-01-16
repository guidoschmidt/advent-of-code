const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 11;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8) !std.ArrayList(usize) {
    var stones = std.ArrayList(usize).init(allocator);
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, trimmed, " ");
    while (it.next()) |n| {
        const num = std.fmt.parseInt(usize, n, 10) catch 0;
        try stones.append(num);
    }
    return stones;
}

fn countDigits(number: usize) usize {
    var r: usize = 0;
    var n = number;
    while (n > 0) : (r += 1) {
        n /= 10;
    }
    return r;
}

fn splitNumber(number: usize, digit_count: usize) [2]usize {
    const div: usize = std.math.pow(usize, 10, digit_count / 2);
    const left: usize = number / div;
    const right: usize = @intFromFloat(@mod(@as(f64, @floatFromInt(number)), @as(f64, @floatFromInt(div))));
    return [2]usize{ left, right };
}

fn printStones(input: []const usize) void {
    for (input) |stone| {
        std.debug.print("{d} ", .{stone});
    }
    std.debug.print("\n\n", .{});
}

fn apply(allocator: Allocator, input: []const usize) !std.ArrayList(usize) {
    var result = std.ArrayList(usize).init(allocator);
    for (input) |stone| {
        if (stone == 0) {
            try result.append(1);
            continue;
        }

        const digit_count = countDigits(stone);
        if (@mod(digit_count, 2) == 0) {
            const split = splitNumber(stone, digit_count);
            try result.append(split[0]);
            try result.append(split[1]);
            continue;
        }

        try result.append(stone * 2024);
    }
    return result;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var stones = try parseInput(allocator, input);
    printStones(stones.items);

    for (0..25) |_| {
        const prev_count = stones.items.len;
        const new = try apply(allocator, stones.items);
        stones.deinit();
        stones = new;
        const new_count = stones.items.len;
        log.info("{d}", .{@abs(new_count - prev_count)});
        // printStones(stones.items);
        // std.debug.print("\nResult It #{d}: {d}", .{ i, stones.items.len });
        // aoc.blockAskForNext();
    }

    std.debug.print("\nResult: {d}", .{stones.items.len});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var stones = try parseInput(allocator, input);
    printStones(stones.items);

    for (0..75) |i| {
        log.info("{d}", .{i});
        const new = try apply(allocator, stones.items);
        stones.deinit();
        stones = new;
        std.debug.print("\nResult: {d}\n", .{stones.items.len});
    }

    std.debug.print("\nResult: {d}", .{stones.items.len});
}

test "simple test" {
    const a = countDigits(1);
    try std.testing.expectEqual(a, @as(usize, 1));

    const b = countDigits(123);
    try std.testing.expectEqual(b, @as(usize, 3));

    const c = countDigits(7777777);
    try std.testing.expectEqual(c, @as(usize, 7));

    const split_a = splitNumber(12, 2);
    try std.testing.expectEqual(split_a, [2]usize{ 1, 2 });

    const split_b = splitNumber(3344, 4);
    try std.testing.expectEqual(split_b, [2]usize{ 33, 44 });

    const split_c = splitNumber(11223344, 8);
    try std.testing.expectEqual(split_c, [2]usize{ 1122, 3344 });

    const split_d = splitNumber(1000, 4);
    try std.testing.expectEqual(split_d, [2]usize{ 10, 0 });

    const long: usize = 123456654321;
    const long_digit_count = countDigits(long);
    try std.testing.expectEqual(long_digit_count, @as(usize, 12));
    const split_long = splitNumber(long, long_digit_count);
    try std.testing.expectEqual(split_long, [2]usize{ 1234567, 8910 });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    // try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
