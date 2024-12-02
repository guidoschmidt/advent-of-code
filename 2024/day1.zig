const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    left: []isize,
    right: []isize,
    row_count: usize,
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    var row_it = std.mem.split(u8, input, "\n");
    var row_count: usize = 0;
    while (row_it.next()) |row| {
        if (row.len == 0) break;
        row_count += 1;
    }
    row_it.reset();

    var left: []isize = try allocator.alloc(isize, row_count);
    var right: []isize = try allocator.alloc(isize, row_count);

    var idx: usize = 0;
    while (row_it.next()) |row| : (idx += 1) {
        if (row.len == 0) break;
        // log.info("Row: {s}", .{row});
        var it = std.mem.split(u8, row, " ");
        var lstr = it.next().?;
        var rstr = it.next().?;
        while (it.next()) |n| {
            rstr = n;
        }
        lstr = std.mem.trim(u8, lstr, " ");
        rstr = std.mem.trim(u8, rstr, " ");
        rstr = std.mem.trim(u8, rstr, "\n");
        const l = try std.fmt.parseInt(isize, lstr, 10);
        const r = try std.fmt.parseInt(isize, rstr, 10);
        // log.info("L {s}: {d},", .{ lstr, l });
        // log.info("R {s}: {d}", .{ rstr, r });
        left[idx] = l;
        right[idx] = r;
    }

    return ParseResult{
        .left = left,
        .right = right,
        .row_count = row_count,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);
    const vec_size: usize = 1000;

    std.mem.sort(isize, parsed.right, {}, comptime std.sort.asc(isize));
    std.mem.sort(isize, parsed.left, {}, comptime std.sort.asc(isize));

    var vec_left: @Vector(vec_size, isize) = @splat(0);
    var vec_right: @Vector(vec_size, isize) = @splat(0);

    for (0..parsed.row_count) |i| {
        vec_left[i] = parsed.left[i];
        vec_right[i] = parsed.right[i];
    }

    const vec_diff = @abs(vec_right - vec_left);
    const result = @reduce(.Add, vec_diff);
    std.debug.print("Result: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);
    const vec_size: usize = 1000;

    var similarities = try allocator.alloc(isize, parsed.row_count);
    for (0..parsed.row_count) |i| {
        const l = parsed.left[i];
        similarities[i] = 0;
        for (0..parsed.row_count) |j| {
            const r = parsed.right[j];
            if (l == r)
                similarities[i] += 1;
        }
    }

    var vec_left: @Vector(vec_size, isize) = @splat(0);
    var vec_similarities: @Vector(vec_size, isize) = @splat(0);
    for (0..parsed.row_count) |i| {
        vec_left[i] = parsed.left[i];
        vec_similarities[i] = similarities[i];
    }

    const vec_score: @Vector(vec_size, isize) = vec_left * vec_similarities;
    const result = @reduce(.Add, vec_score);
    std.debug.print("Result: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, 1, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, 1, .PUZZLE, part2);
}
