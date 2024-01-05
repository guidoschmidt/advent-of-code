const std = @import("std");
const puzzle_input = @import("./puzzle_input.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try puzzle_input.getPuzzleInput(allocator, 7);
    std.debug.print("\n{s}", .{ input });
}
