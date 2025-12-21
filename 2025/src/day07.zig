const std = @import("std");
const aoc = @import("aoc");
const t = @import("libs").term;
const Map = @import("libs").Map;

const DAY: u5 = 7;

const Allocator = std.mem.Allocator;
const log = std.log;

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-07");
    // std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    const map: Map = try .init(allocator, input);

    var start: @Vector(2, usize) = @splat(0);
    var splitters: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);

    // std.debug.print("{d} x {d}\n", .{ map.cols, map.rows });

    for (0..map.rows) |y| {
        for (0..map.cols) |x| {
            switch (map.get(x, y)) {
                'S' => start = .{ x, y },
                '^' => try splitters.append(.{ x, y }),
                else => continue,
            }
        }
    }

    var beams: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);
    try beams.append(start);
    var splits: usize = 0;
    while (beams.pop()) |b| {
        std.mem.sort(@Vector(2, usize), beams.items, {}, comptime struct {
            pub fn f(_: void, beam1: @Vector(2, usize), beam2: @Vector(2, usize)) bool {
                return beam1[1] > beam2[1];
            }
        }.f);

        map.animate();
        const curr: @Vector(2, usize) = .{ b[0], b[1] };
        if (curr[0] < 0 or
            curr[0] > map.cols - 1 or
            curr[1] > map.rows - 1)
        {
            continue;
        }
        switch (map.get(curr[0], curr[1])) {
            'S' => try beams.append(.{ curr[0], curr[1] + 1 }),
            '.' => try beams.append(.{ curr[0], curr[1] + 1 }),
            '^' => {
                splits += 1;
                try beams.append(.{ curr[0] - 1, curr[1] });
                try beams.append(.{ curr[0] + 1, curr[1] });
            },
            else => continue,
        }
        map.set(curr[0], curr[1], '|');
    }
    // std.debug.print("{f}\n", .{map});

    std.debug.print("# Splitters: {d}\n", .{splitters.items.len});
    std.debug.print("Result: {d}\n", .{splits});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-07");
    // std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    const map: Map = try .init(allocator, input);

    var start: @Vector(2, usize) = @splat(0);
    var splitters: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);

    // std.debug.print("{d} x {d}\n", .{ map.cols, map.rows });

    for (0..map.rows) |y| {
        for (0..map.cols) |x| {
            switch (map.get(x, y)) {
                'S' => start = .{ x, y },
                '^' => try splitters.append(.{ x, y }),
                else => continue,
            }
        }
    }

    var beams: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);
    try beams.append(start);
    var timelines: usize = 1;
    while (beams.pop()) |b| {
        std.mem.sort(@Vector(2, usize), beams.items, {}, comptime struct {
            pub fn f(_: void, beam1: @Vector(2, usize), beam2: @Vector(2, usize)) bool {
                return beam1[0] > beam2[0];
            }
        }.f);

        const curr: @Vector(2, usize) = .{ b[0], b[1] };

        if (curr[0] < 0 or
            curr[0] > map.cols - 1 or
            curr[1] > map.rows - 1)
        {
            continue;
        }

        // const orig = map.get(curr[0], curr[1]);
        // map.set(curr[0], curr[1], '|');
        // map.animate();
        // map.set(curr[0], curr[1], orig);

        switch (map.get(curr[0], curr[1])) {
            'S' => try beams.append(.{ curr[0], curr[1] + 1 }),
            '.' => try beams.append(.{ curr[0], curr[1] + 1 }),
            '^' => {
                timelines += 1;
                try beams.append(.{ curr[0] - 1, curr[1] });
                try beams.append(.{ curr[0] + 1, curr[1] });
            },
            else => continue,
        }
    }
    // std.debug.print("{f}\n", .{map});

    std.debug.print("# Splitters: {d}\n", .{splitters.items.len});
    std.debug.print("Result: {d}\n", .{timelines});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    // try aoc.runPart(allocator, part2);
}
