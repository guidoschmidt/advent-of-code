const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 3;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-03");
    var pos: @Vector(2, isize) = @splat(0);
    var map: std.hash_map.AutoHashMap(@Vector(2, isize), usize) = .init(allocator);
    defer map.deinit();
    for (input) |d| {
        switch (d) {
            '^' => pos += .{ 0, -1 },
            '>' => pos += .{ 1, 0 },
            'v' => pos += .{ 0, 1 },
            '<' => pos += .{ -1, 0 },
            else => unreachable,
        }
        if (map.get(pos)) |v| {
            try map.put(pos, v + 1);
            continue;
        }
        try map.put(pos, 1);
    }

    var result: usize = 0;
    var it = map.iterator();
    while (it.next()) |_| {
        result += 1;
    }

    std.debug.print("Result: {d}\n", .{result});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-03");
    var pos: [2]@Vector(2, isize) = .{ @splat(0), @splat(0) };
    var map: std.hash_map.AutoHashMap(@Vector(2, isize), usize) = .init(allocator);
    defer map.deinit();
    try map.put(pos[0], 1);
    var i: usize = 0;
    for (input) |d| {
        switch (d) {
            '^' => pos[i] += .{ 0, -1 },
            '>' => pos[i] += .{ 1, 0 },
            'v' => pos[i] += .{ 0, 1 },
            '<' => pos[i] += .{ -1, 0 },
            else => unreachable,
        }
        if (map.get(pos[i])) |v| {
            try map.put(pos[i], v + 1);
            continue;
        }
        try map.put(pos[i], 1);

        i = @mod(i + 1, 2);
    }

    var result: usize = 0;
    var it = map.iterator();
    while (it.next()) |_| {
        result += 1;
    }

    std.debug.print("Result: {d}\n", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
