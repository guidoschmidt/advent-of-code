/// Small helper executable that allows to fetch the puzzle input from
/// https://adventofcode.com/$YEAR/day/$DAY/input
/// CLI arguments are
/// - year
/// - day
/// - Optional file path to store the puzzle input to disk. This is sometimes useful,
///   e.g. if you want to implement a solution in another language or just need to
///   peek into the data
const std = @import("std");
const types = @import("types.zig");
const input = @import("input.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // binary name

    if (args.inner.count < 3) {
        _ = try std.fs.File.stdout().write("Please provide 2 arguments: YEAR DAY, e.g. 2025 7");
        return;
    }

    const YEAR = try std.fmt.parseInt(types.Year, args.next().?, 10);
    const DAY = try std.fmt.parseInt(types.Day, args.next().?, 10);
    const puzzle_file_path = args.next();

    const response = try input.getPuzzleInputFromServer(allocator, YEAR, DAY, puzzle_file_path);
    try std.fs.File.stdout().writeAll(response);
}
