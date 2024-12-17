const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 9;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8) !std.ArrayList(usize) {
    var disk_map = std.ArrayList(usize).init(allocator);
    for (input) |c| {
        if (c == '\n') break;
        const num = try std.fmt.charToDigit(c, 10);
        try disk_map.append(@intCast(num));
    }
    return disk_map;
}

fn printMap(comptime T: type, map: []const T) void {
    for (map) |d| {
        if (d == -1) {
            std.debug.print("{c}", .{'.'});
        } else {
            std.debug.print("{d}", .{d});
        }
    }
    std.debug.print("\n", .{});
}

fn calcChecksum(block_map: []const isize) !usize {
    var cksm: usize = 0;
    for (0..block_map.len) |i| {
        if (block_map[i] == -1) break;
        const num: usize = @intCast(block_map[i]);
        cksm += i * num;
    }
    return cksm;
}

fn explode(allocator: Allocator, disk_map: []const usize) !void {
    var block_map = std.ArrayList(isize).init(allocator);
    var idx: usize = 0;
    for (0..disk_map.len) |i| {
        const count = disk_map[i];
        if (@mod(i, 2) == 1) {
            for (0..count) |j| {
                log.info("{d} -> .", .{j});
                try block_map.append(-1);
            }
            idx += 1;
        } else {
            for (0..count) |j| {
                log.info("{d} -> {d}", .{ j, idx });
                try block_map.append(@intCast(idx));
            }
        }
    }

    printMap(isize, block_map.items);

    var s: usize = 0;
    var e: usize = block_map.items.len - 1;
    while (s < e) {
        if (block_map.items[s] == -1) {
            std.mem.swap(isize, &block_map.items[s], &block_map.items[e]);
            e -= 1;
        } else {
            s += 1;
        }
    }

    printMap(isize, block_map.items);

    std.debug.print("\nDisk Map size: {d}", .{disk_map.len});
    std.debug.print("\nBlock Map size: {d}", .{block_map.items.len});

    const cksm = try calcChecksum(block_map.items);
    std.debug.print("\n\nResult: {d}", .{cksm});
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const disk_map = try parseInput(allocator, input);
    try explode(allocator, disk_map.items);
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
