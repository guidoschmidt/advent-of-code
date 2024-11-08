const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

fn printMap(map: *[][]u8) void {
    std.debug.print("\n\n", .{});
    for (0..map.len) |x| {
        const row = map.*[x];
        std.debug.print("\n", .{});
        for (0..row.len) |y| {
            std.debug.print("{c}", .{map.*[x][y]});
        }
        std.debug.print("   {d: >3}", .{map.len - x});
    }
}

fn rollNorth(map: *[][]u8, x: usize, y: usize) void {
    if (x == 0) return;
    const o = x - 1;
    if (map.*[o][y] == '.') {
        map.*[o][y] = 'O';
        map.*[x][y] = '.';
        rollNorth(map, o, y);
    }
}

fn rollEast(map: *[][]u8, x: usize, y: usize) void {
    if (y >= map.len) return;
    const o = y + 1;
    if (map.*[x][o] == '.') {
        map.*[x][o] = 'O';
        map.*[x][y] = '.';
        rollNorth(map, x, o);
    }
}

fn rollSouth(map: *[][]u8, x: usize, y: usize) void {
    if (x >= map.len) return;
    const o = x + 1;
    if (map.*[o][y] == '.') {
        map.*[o][y] = 'O';
        map.*[x][y] = '.';
        rollNorth(map, o, y);
    }
}

fn rollWest(map: *[][]u8, x: usize, y: usize) void {
    if (y == 0) return;
    const o = y - 1;
    if (map.*[x][o] == '.') {
        map.*[x][o] = 'O';
        map.*[x][y] = '.';
        rollNorth(map, x, o);
    }
}

fn sumLoad(map: *[][]u8) usize {
    var sum: usize = 0;
    for (0..map.len) |x| {
        const row = map.*[x];
        for (0..row.len) |y| {
            const el = map.*[x][y];
            if (el == 'O') {
                sum += map.len - x;
            }
        }
    }
    return sum;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");
    const data = try allocator.alloc(u8, input.len);
    _ = std.mem.replace(u8, input, "\n", "", data);

    const width = row_it.peek().?.len;
    var height: usize = 0;
    while (row_it.next()) |_| {
        height += 1;
    }
    std.debug.print("\nMap size {d} x {d}", .{ width, height });

    var map: [][]u8 = try allocator.alloc([]u8, height);
    defer allocator.free(map);
    for (0..height) |h| {
        map[h] = try allocator.alloc(u8, width);
    }

    for (0..width) |w| {
        for (0..height) |h| {
            map[w][h] = data[w * width + h];
        }
    }

    printMap(&map);

    for (0..map.len) |x| {
        const row = map[x];
        for (0..row.len) |y| {
            const entry = map[x][y];
            switch (entry) {
                'O' => rollNorth(&map, x, y),
                else => {},
            }
        }
    }

    printMap(&map);

    const load = sumLoad(&map);
    std.debug.print("\nResult: {d}", .{load});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try aoc.runPart(allocator, 2023, 14, .EXAMPLE, part1);
    try aoc.runPart(allocator, 2023, 14, .EXAMPLE, part2);
}
