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

    const INPUT_TYPE: types.PuzzleInput = @enumFromInt(try std.fmt.parseInt(
        @typeInfo(types.PuzzleInput).@"enum".tag_type,
        args.next().?,
        10,
    ));
    const YEAR = try std.fmt.parseInt(types.Year, args.next().?, 10);
    const DAY = try std.fmt.parseInt(types.Day, args.next().?, 10);
    const puzzle_file_path = args.next();

    std.debug.print("{any}: {d}-{d}\n", .{ YEAR, DAY, INPUT_TYPE });

    const sub_folder = switch (INPUT_TYPE) {
        .EXAMPLE => "example",
        .PUZZLE => "puzzle",
    };
    const file_name = try std.fmt.allocPrint(allocator, "day{d:0>2.}", .{DAY});
    const file_path = try std.fs.path.join(allocator, &.{ ".", puzzle_file_path.?, sub_folder, file_name });
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        switch (err) {
            error.FileNotFound => {
                _ = switch (INPUT_TYPE) {
                    .PUZZLE => {
                        const response = try input.getPuzzleInputFromServer(
                            allocator,
                            YEAR,
                            DAY,
                            file_path,
                        );
                        try std.fs.File.stdout().writeAll(response);
                        return;
                    },
                    .EXAMPLE => {
                        _ = try std.fs.cwd().createFile(file_path, .{});
                        std.debug.print("🎁 Created empty {s}. Make sure to feed in data.\n", .{
                            file_path,
                        });
                        return;
                    },
                };
            },
            else => {
                @panic("Error not handled");
            },
        }
    };

    // Read existing file
    const end = try file.getEndPos();
    const result = try file.readToEndAlloc(allocator, end);

    try std.fs.File.stdout().writeAll(result);
}
