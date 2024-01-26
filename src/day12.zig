//! Sources:
//! - https://stackoverflow.blog/2022/01/31/the-complete-beginners-guide-to-dynamic-programming/
//! - https://de.wikipedia.org/wiki/Dynamische_Programmierung
//! - https://qsantos.fr/2024/01/04/dynamic-programming-is-not-black-magic/
//! - https://github.com/qsantos/advent-of-code/blob/master/2023/day12/src/main.rs#L6-L46
//!
//! Zig Examples to examplify the concept
//! - https://github.com/guidoschmidt/examples.zig/blob/main/src/dynamic-programming.zig
//! - https://github.com/guidoschmidt/examples.zig/blob/main/src/pair-of-numbers.zig

const std = @import("std");
const common = @import("common.zig");
const Allocator = std.mem.Allocator;

fn visualizeCache(cache: *[][]usize) void {
    std.debug.print("\nCACHE:\n[", .{});
    for(0..cache.len) |i| {
        std.debug.print("{any}.", .{ cache.*[i] });
    }
    std.debug.print("]\n", .{});
}

fn countCombinationsMemoizedNew(allocator: Allocator, springs: []const u8, groups: []const usize) !usize {
    // std.debug.print("\n-----------------------\nSprings , Groups:\n{s} , {any}\n\n", .{ springs, groups });
    var cache = try allocator.alloc([]usize, springs.len + 1);


    // Initialize the cache
    for(0..springs.len + 1) |i| {
        cache[i] = try allocator.alloc(usize, groups.len + 1);
        for(0..groups.len + 1) |j| {
            cache[i][j] = 0;
        }
    }
    cache[0][0] = 1;

    // Release memory of cache
    defer {
        for (0..springs.len + 1) |i| {
            allocator.free(cache[i]);
        }
        allocator.free(cache);
    }

    for (1..springs.len + 1) |s| {
        const spring = springs[s - 1];
        // std.debug.print("\n{s}LOOP {c}{s}", .{ common.green, spring, common.clear });

        for (0..groups.len + 1) |g| {
            // std.debug.print("\ns={d} / g={d}", .{ s, g });

            var count: usize = 0;

            // visualizeCache(&cache);

            // Simple case
            if (spring == '.' or spring == '?') {
                const prev = cache[s - 1][g];
                count += prev;
                // std.debug.print("\nCASE 1 {s}no group:{s} {d}, [+{d}]", .{ common.light_blue, common.clear, count, prev });
            }

            // Groups
            if (g > 0) {
                const group_size = groups[g - 1];
                // std.debug.print("\nCASE 2 {s}group of size {d}{s}", .{ common.light_blue, group_size, common.clear });
                const partial = springs[(s -| 1) -| (group_size -| 1)..s];
                // std.debug.print("\nPartial: {s}{s}{s}", .{ common.yellow, partial, common.clear });
                var test_all = true;
                for (partial) |item| {
                    test_all = test_all and (item == '?' or item == '#');
                }

                if (s >= group_size) {
                    // std.debug.print("\nCASE 3 {s}s={d} >= group_size={d}{s}", .{ common.light_blue, s, group_size, common.clear });
                    if (test_all) {
                        if ((s) == group_size) {
                            // std.debug.print("\nCASE 3.1 {s}s={d} == group_size={d}{s}", .{ common.light_blue, s, group_size, common.clear });
                            const prev = cache[0][g - 1];
                            count += prev;
                            // std.debug.print("{d} [+{d}]", .{ count, prev });
                        } else {
                            // std.debug.print("\nCASE 4 {s}group_size={d} > {d}{s}", .{ common.light_blue, group_size, g, common.clear });
                            const separator = springs[(s - 1) - (group_size - 1) - 1];
                            // std.debug.print("{c}", .{ separator });
                            if (separator == '.' or separator == '?') {
                                const prev = cache[s - group_size - 1][g - 1];
                                count += prev;
                                // std.debug.print("{d} [+{d}]", .{ count, prev });
                            }
                        }
                    }
                }
            }
            // std.debug.print("\n    {s}---> {d}{s}", .{ common.blue, count, common.clear });
            cache[s][g] = count;
        }
        // std.debug.print("\n", .{});
    }

    // visualizeCache(&cache);
    return cache[springs.len][groups.len];
}

pub fn unfold(allocator: Allocator, springs: []const u8, groups: []const usize) !struct{springs: []const u8, groups: []const usize} {
    var unfolded_springs = try allocator.alloc(u8, ((springs.len + 1) * 5) - 1);

    var start: usize = 0;
    for(0..5) |_| {
        const end = start + springs.len + 1;
        for (unfolded_springs[start..end - 1], springs) |*d, s| {
            d.* = s;
        }
        if (end < unfolded_springs.len)
            unfolded_springs[end - 1] = '?';
        start = end;
    }

    var unfolded_groups = try allocator.alloc(usize, groups.len * 5);
    for (0..unfolded_groups.len) |idx| {
        const mod_idx = try std.math.mod(usize, idx, groups.len);
        unfolded_groups[idx] = groups[mod_idx];
    }

    // std.debug.print("\n\n--- UNFOLDING ---\n\x1B[35m{s}\n\x1B[36m", .{ springs });
    // var i: usize = 0;
    // var j: usize = 0;
    // while(i < unfolded_springs.len) : (i += 1) {
    //     if (i > 0 and (try std.math.mod(usize, i - j, springs.len)) == 0) {
    //         std.debug.print("\x1B[33m___{c}___\x1B[0m", .{ unfolded_springs[i] });
    //         i += 1;
    //         j += 1;
    //     }
    //     std.debug.print("\x1B[36m{c}", .{ unfolded_springs[i] });
    // }
    // std.debug.print("\x1B[0m\n[{d}] → [{d}]", .{ springs.len, unfolded_springs.len });
    // std.debug.print("\n{any}\n{any}", .{ groups, unfolded_groups });

    return .{
        .springs = unfolded_springs,
        .groups = unfolded_groups,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var sum: u128 = 0;

    while(row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, " ");
        const springs = entry_it.next().?;

        const groups_str = entry_it.next().?;
        var groups_it = std.mem.tokenize(u8, groups_str, ",");
        var groups_list  = std.ArrayList(usize).init(allocator);
        var i: usize = 0;
        while(groups_it.next()) |g| : (i += 1) {
            const n = try std.fmt.parseInt(usize, g, 10);
            try groups_list.append(n);
        }
        const groups = groups_list.items;
        sum += try countCombinationsMemoizedNew(allocator, springs, groups);
    }

    std.debug.print("\n\nResult: {d}\n", .{ sum });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var sum: usize = 0;

    while(row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, " ");
        const springs = entry_it.next().?;

        const groups_str = entry_it.next().?;
        var groups_it = std.mem.tokenize(u8, groups_str, ",");
        var groups_list  = std.ArrayList(usize).init(allocator);
        var i: usize = 0;
        while(groups_it.next()) |g| : (i += 1) {
            const n = try std.fmt.parseInt(usize, g, 10);
            try groups_list.append(n);
        }

        std.debug.print("\n{s} -- {any}", .{ springs, groups_list.items });
        const unfolded = try unfold(allocator, springs, groups_list.items);
        defer {
            allocator.free(unfolded.springs);
            allocator.free(unfolded.groups);
            groups_list.deinit();
        }
        
        const result = try countCombinationsMemoizedNew(allocator, unfolded.springs, unfolded.groups);
        std.debug.print("\n\x1B[32m→ Possibilities {d}\x1B[0m", .{ result });
        sum += result;
    }

    std.debug.print("\n\nResult: {d}\n", .{ sum });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try common.runDay(allocator, 12, .PUZZLE, part1, part2);
}

test "simple cases" {
    var allocator = std.testing.allocator;

    // Single chars
    var springs: []const u8 = "?";
    var groups = &[_]usize{ 1 };
    var result: usize = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 1);

    springs = ".";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 0);

    springs = "#";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 1);

    // Two characters
    springs = "??";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 2);

    springs = "..";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 0);

    springs = "##";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 0);

    // Three characters
    springs = "???";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 3);

    springs = "...";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 0);

    springs = "###";
    groups = &[_]usize{ 1 };
    result = try countCombinationsMemoizedNew(allocator, springs, groups);
    try std.testing.expectEqual(result, 0);
}
