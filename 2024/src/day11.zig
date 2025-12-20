const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 11;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8) !std.array_list.Managed(usize) {
    var stones = std.array_list.Managed(usize).init(allocator);
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

fn apply(allocator: Allocator, input: []const usize) !std.array_list.Managed(usize) {
    var result = std.array_list.Managed(usize).init(allocator);
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

fn applyWithMap(allocator: Allocator, input: std.AutoArrayHashMap(usize, usize)) !std.AutoArrayHashMap(usize, usize) {
    var new_stone_map = std.AutoArrayHashMap(usize, usize).init(allocator);

    var input_it = input.iterator();

    while (input_it.next()) |it| {
        const stone = it.key_ptr.*;
        const prev_count = it.value_ptr.*;

        if (stone == 0) {
            const prev_ones = new_stone_map.get(1) orelse 0;
            try new_stone_map.put(1, prev_count + prev_ones);
            continue;
        }

        const digit_count = countDigits(stone);
        if (@mod(digit_count, 2) == 0) {
            const split = splitNumber(stone, digit_count);
            const split_l_prev = new_stone_map.get(split[0]) orelse 0;
            try new_stone_map.put(split[0], prev_count + split_l_prev);
            const split_r_prev = new_stone_map.get(split[1]) orelse 0;
            try new_stone_map.put(split[1], prev_count + split_r_prev);
            continue;
        }

        const mul = stone * 2024;
        try new_stone_map.put(mul, prev_count);
    }

    return new_stone_map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var stones = try parseInput(allocator, input);
    printStones(stones.items);

    for (0..25) |_| {
        const new = try apply(allocator, stones.items);
        // printStones(new.items);
        stones.deinit();
        stones = new;
    }

    std.debug.print("\nResult: {d}", .{stones.items.len});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const stones = try parseInput(allocator, input);
    printStones(stones.items);

    var stones_map = std.AutoArrayHashMap(usize, usize).init(allocator);
    for (stones.items) |stone| {
        const prev = stones_map.get(stone) orelse 0;
        try stones_map.put(stone, prev + 1);
    }

    var count: usize = 0;
    var stones_it = stones_map.iterator();
    for (0..75) |_| {
        // log.info("{d}", .{i});
        const new = try applyWithMap(allocator, stones_map);
        stones_map.deinit();
        stones_map = new;
        stones_it = stones_map.iterator();
        count = 0;
        while (stones_it.next()) |it| {
            // log.info("[{d}]: {d}", .{ it.key_ptr.*, it.value_ptr.* });
            count += it.value_ptr.*;
        }
    }

    std.debug.print("\nResult: {d}", .{count});
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
