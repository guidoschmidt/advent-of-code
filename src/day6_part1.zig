const std = @import("std");
const sw = @import("stopwatch.zig");
const puzzle_input = @import("puzzle_input.zig");

pub fn main() !void {
    sw.start();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try puzzle_input.getPuzzleInput(allocator, 6);
    std.debug.print("\n{s}", .{ input });

    const time = sw.stop();
    std.debug.print("\n{d:3} ms\n", .{time});
}
