const std = @import("std");
const aoc = @import("aoc");

const YEAR: u12 = 2025;
const DAY: u5 = 4;

const Allocator = std.mem.Allocator;
const log = std.log;

fn findAccessibleRolls(map: []u8, rows: usize, cols: usize) !usize {
    var result: usize = 0;

    for (0..cols) |i| {
        for (0..rows) |j| {
            const x: isize = @intCast(j);
            const y: isize = @intCast(i);
            var rolls_count: usize = 0;

            for (0..3) |yy| {
                inner: for (0..3) |xx| {
                    const xo = x + @as(isize, @intCast(xx)) - 1;
                    const yo = y + @as(isize, @intCast(yy)) - 1;
                    if (xo < 0 or
                        yo < 0 or
                        xo > rows - 1 or
                        yo > cols - 1 or
                        (xo == x and yo == y)) continue :inner;
                    const map_value = map[@intCast((xo * @as(isize, @intCast(rows))) + yo)];
                    if (map_value == '@' or map_value == 'x') {
                        rolls_count += 1;
                    }
                }
            }

            if (map[@intCast((x * @as(isize, @intCast(rows))) + y)] != '.' and rolls_count < 4) {
                map[@intCast((x * @as(isize, @intCast(rows))) + y)] = '.';
                result += 1;
            }
        }
    }

    // --- Print the map to visualise what's going on
    // for (0..cols) |_x| {
    //     for (0..rows) |_y| {
    //         std.debug.print("{c} ", .{map[(_x * rows) + _y]});
    //     }
    //     std.debug.print("\n", .{});
    // }

    return result;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    _ = input;
    const input_embed = std.mem.trimEnd(u8, @embedFile("puzzle-04"), "\n");

    var it = std.mem.tokenizeSequence(u8, input_embed, "\n");
    const cols = it.peek().?.len;
    const rows = input_embed.len / cols;
    std.debug.print("Map size: {d} x {d}\n", .{ cols, rows });

    const map = try std.mem.replaceOwned(u8, allocator, input_embed, "\n", "");
    defer allocator.free(map);

    const result = try findAccessibleRolls(map, rows, cols);
    std.debug.print("Result: {d}\n", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = input;
    const input_embed = std.mem.trimEnd(u8, @embedFile("puzzle-04"), "\n");

    var it = std.mem.tokenizeSequence(u8, input_embed, "\n");
    const cols = it.peek().?.len;
    const rows = input_embed.len / cols;
    std.debug.print("Map size: {d} x {d}\n", .{ cols, rows });

    const map = try std.mem.replaceOwned(u8, allocator, input_embed, "\n", "");
    defer allocator.free(map);

    var step_result = try findAccessibleRolls(map, rows, cols);
    var summed_result: usize = step_result;
    while (step_result > 0) {
        step_result = try findAccessibleRolls(map, rows, cols);
        summed_result += step_result;
    }
    std.debug.print("Result: {d}\n", .{summed_result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, DAY, .EXAMPLE, part1);
    try aoc.runPart(allocator, DAY, .EXAMPLE, part2);
}
