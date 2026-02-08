const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 2;

const Allocator = std.mem.Allocator;
const log = std.log;

fn calcSurface(input: @Vector(3, usize)) usize {
    const l = input[0];
    const w = input[1];
    const h = input[2];
    const slack = @min(l * w, @min(w * h, h * l));
    const area = 2 * l * w + 2 * w * h + 2 * h * l;
    return area + slack;
}

fn calcRibbonLength(input: @Vector(3, usize)) usize {
    const bow = @reduce(.Mul, input);
    var idx_a: usize = 0;
    var idx_b: usize = 1;
    var idx_longest: usize = 0;
    for (1..3) |i| {
        if (input[i] > input[idx_longest]) idx_longest = i;
    }
    if (idx_longest == 0) {
        idx_a = 1;
        idx_b = 2;
    }
    if (idx_longest == 1) {
        idx_a = 0;
        idx_b = 2;
    }
    if (idx_longest == 2) {
        idx_a = 0;
        idx_b = 1;
    }
    const ribbon = input[idx_a] * 2 + input[idx_b] * 2;
    return ribbon + bow;
}

fn part1(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("puzzle-02");
    var reader: std.io.Reader = .fixed(input);
    var total: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        var numbers_it = std.mem.splitScalar(u8, line, 'x');
        var size: @Vector(3, usize) = @splat(0);
        var i: usize = 0;
        while (numbers_it.next()) |n| : (i += 1) {
            const v = try std.fmt.parseInt(usize, n, 10);
            size[i] = v;
        }
        total += calcSurface(size);
    }

    std.debug.print("Result: {d}\n", .{total});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("puzzle-02");
    var reader: std.io.Reader = .fixed(input);
    var total: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        var numbers_it = std.mem.splitScalar(u8, line, 'x');
        var size: @Vector(3, usize) = @splat(0);
        var i: usize = 0;
        while (numbers_it.next()) |n| : (i += 1) {
            const v = try std.fmt.parseInt(usize, n, 10);
            size[i] = v;
        }
        total += calcRibbonLength(size);
    }

    std.debug.print("Result: {d}\n", .{total});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
