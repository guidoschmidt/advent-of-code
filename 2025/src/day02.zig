const std = @import("std");
const aoc = @import("aoc");

const YEAR: u12 = 2025;
const DAY: u5 = 2;

const Allocator = std.mem.Allocator;
const log = std.log;

fn countDigits(number: usize) usize {
    var r: usize = 0;
    var n = number;
    while (n > 0) : (r += 1) {
        n /= 10;
    }
    return r;
}

fn part1(allocator: Allocator) anyerror!void {
    const input_embed = @embedFile("puzzle-02");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input_embed});

    var result: usize = 0;

    var reader: std.Io.Reader = .fixed(std.mem.trimEnd(u8, input_embed, "\n"));
    while (try reader.takeDelimiter(',')) |line| {
        var ranges = std.mem.splitSequence(u8, line, "-");
        const lhs = ranges.next().?;
        const rhs = ranges.next().?;
        const lower = try std.fmt.parseInt(u64, lhs, 10);
        const upper = try std.fmt.parseInt(u64, rhs, 10);
        for (lower..upper + 1) |id| {
            const id_str = try std.fmt.allocPrint(allocator, "{d}", .{id});
            if (try std.math.rem(usize, countDigits(id), 2) == 0) {
                const left = id_str[0 .. id_str.len / 2];
                const right = id_str[id_str.len / 2 ..];
                defer allocator.free(id_str);
                if (std.mem.eql(u8, left, right)) result += id;
            }
        }
    }

    std.debug.print("Result: {d}\n", .{result});
}

fn part2(allocator: Allocator) anyerror!void {
    const input_embed = @embedFile("puzzle-02");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input_embed});

    var result: usize = 0;

    var reader: std.Io.Reader = .fixed(std.mem.trimEnd(u8, input_embed, "\n"));
    while (try reader.takeDelimiter(',')) |line| {
        var ranges = std.mem.splitSequence(u8, line, "-");
        const lhs = ranges.next().?;
        const rhs = ranges.next().?;
        const lower = try std.fmt.parseInt(u64, lhs, 10);
        const upper = try std.fmt.parseInt(u64, rhs, 10);
        for (lower..upper + 1) |id| {
            const id_str = try std.fmt.allocPrint(allocator, "{d}", .{id});
            defer allocator.free(id_str);

            var invalid = false;

            const digit_count = countDigits(id);
            check: for (1..digit_count) |x| {
                const w = digit_count - x;
                const remainder = try std.math.rem(usize, digit_count, w);
                if (remainder > 0) continue;

                var window_it = std.mem.window(u8, id_str, w, w);
                const search = window_it.next().?;
                while (window_it.next()) |seq| {
                    if (!std.mem.eql(u8, search, seq)) {
                        continue :check;
                    }
                }
                invalid = true;
                break :check;
            }
            if (invalid) result += id;
        }
    }

    std.debug.print("Result: {d}\n", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
