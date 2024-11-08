const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    const width = row_it.peek().?.len;
    var height: usize = 0;

    while(row_it.next()) |_| height += 1;
    row_it.reset();

    std.debug.print("\nMap size {d} x {d}", .{ width, height });

    const cleaned_input = try std.mem.replaceOwned(u8, allocator, input, "\n", "");
    for(0..width) |x| {
        for (0..height) |y| {
            const cell = cleaned_input[y * height + x];
            std.debug.print("\n{c}", .{ cell });
        }
    }
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = input;
    _ = gpa;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try aoc.runPart(gpa, 2023, 21, .EXAMPLE, part1);
    try aoc.runPart(gpa, 2023, 21, .EXAMPLE, part2);
}
