const std = @import("std");
const aoc = @import("aoc");

const YEAR: u12 = 2025;
const DAY: u5 = 5;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    var fresh_ingredients: usize = 0;

    const input_embed = @embedFile("puzzle-05");
    const split_at = std.mem.indexOf(u8, input_embed, "\n\n").?;
    const ranges = std.mem.trim(u8, input_embed[0..split_at], "\n");
    const ingredients_ids = std.mem.trim(u8, input_embed[split_at..], "\n");

    var ranges_list: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);
    defer ranges_list.deinit();
    var ranges_reader: std.Io.Reader = .fixed(ranges);
    while (try ranges_reader.takeDelimiter('\n')) |range| {
        const sep = std.mem.indexOf(u8, range, "-").?;
        try ranges_list.append(.{
            try std.fmt.parseInt(usize, range[0..sep], 10),
            try std.fmt.parseInt(usize, range[sep + 1 ..], 10),
        });
    }

    var instructions_reader: std.Io.Reader = .fixed(ingredients_ids);
    while (try instructions_reader.takeDelimiter('\n')) |line| {
        const num = try std.fmt.parseInt(usize, line, 10);
        var is_fresh = false;
        for (ranges_list.items) |range| {
            is_fresh = (num >= range[0] and num <= range[1]);
            if (is_fresh) break;
        }
        if (is_fresh) fresh_ingredients += 1;
    }

    std.debug.print("Result: {d}\n", .{fresh_ingredients});
}

fn part2(allocator: Allocator) anyerror!void {
    const input_embed = @embedFile("puzzle-05");
    const split_at = std.mem.indexOf(u8, input_embed, "\n\n").?;
    const ranges = std.mem.trim(u8, input_embed[0..split_at], "\n");

    var ranges_list: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);
    defer ranges_list.deinit();

    var ranges_reader: std.Io.Reader = .fixed(ranges);
    while (try ranges_reader.takeDelimiter('\n')) |range| {
        const sep = std.mem.indexOf(u8, range, "-").?;
        const lower = try std.fmt.parseInt(usize, range[0..sep], 10);
        const upper = try std.fmt.parseInt(usize, range[sep + 1 ..], 10);

        try ranges_list.append(.{ lower, upper });
    }

    std.mem.sort(@Vector(2, usize), ranges_list.items, {}, comptime struct {
        pub fn f(_: void, a: @Vector(2, usize), b: @Vector(2, usize)) bool {
            return a[0] < b[0];
        }
    }.f);

    for (0..ranges_list.items.len - 1) |r| {
        const curr = ranges_list.items[r];
        const next = ranges_list.items[r + 1];

        // Current range overlaps next range on lower bound of next
        if (curr[1] >= next[0]) {

            // Extend next range on lower end
            ranges_list.items[r + 1][0] = curr[0];

            // Current range overlaps next range on upper bound of next
            if (curr[1] > next[1]) {
                // Extend next range on upper end
                ranges_list.items[r + 1][1] = curr[1];
            }

            // Dismiss current range
            // (as the next range has been expanded and ids shouldn't be
            // counted twice)
            ranges_list.items[r] = .{ 0, 0 };
        }
    }

    var sum: usize = 0;
    for (ranges_list.items) |r| {
        if (r[0] == 0 or r[1] == 0) continue;
        sum += r[1] - r[0] + 1;
    }

    std.debug.print("Result: {d}\n", .{sum});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
