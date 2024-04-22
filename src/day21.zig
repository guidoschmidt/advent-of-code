const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var width = row_it.peek().?;
    var height: usize = 0;

    while(row_it.next()) |_| height += 1;
    row_it.reset();

    std.debug.print("\nMap size {d} x {d}", .{ width, height });

    var cleaned_input = std.mem.replaceOwned(u8, gpa, input, "\n", "");
    for(0..width) |x| {
        for (0..height) |y| {
            var cell = cleaned_input[y * height + x];
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

    try common.runPart(gpa, 21, .EXAMPLE, part1);
}
