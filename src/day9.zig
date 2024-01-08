const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();


fn part1(input: []const u8) void {
    _ = input;
    
}

fn part2(input: []const u8) void {
    _ = input;
    
}

pub fn main() !void {
    try common.runDay(allocator, 9, .PUZZLE, part1, part2);
}
