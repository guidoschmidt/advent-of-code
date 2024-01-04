const std = @import("std");
const sw = @import("stopwatch.zig");
const puzzle_input = @import("puzzle_input.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn resolveRace(comptime T: type, time: T, distance: T) T {
    var wins: T = 0;
    for(1..time) |t| {
        const rest = time - t;
        const traveled = rest * t;
        if (traveled > distance)
            wins += 1;
    }
    return wins;
}

fn part1(input: []const u8) !void {
    std.debug.print("\n########## Part 1 ##########", .{});

    var times = std.ArrayList(u32).init(allocator);
    var dists = std.ArrayList(u32).init(allocator);

    var row_it = std.mem.tokenize(u8, input, "\n");
    while(row_it.next()) |r| {
        var val_it = std.mem.tokenize(u8, r, " ");
        var col = val_it.next().?;
        while(val_it.next()) |v| {
            if (std.mem.eql(u8, col, "Time:")) {
                const number = std.fmt.parseInt(u32, v, 10) catch continue;
                try times.append(number);
            }
            if (std.mem.eql(u8, col, "Distance:")) {
                const number = std.fmt.parseInt(u32, v, 10) catch continue;
                try dists.append(number);
            }
        }
    }

    var result: u32 = 1;
    for (times.items, dists.items) |t, d| {
        const wins = resolveRace(u32, t, d);
        result *= wins;
        std.debug.print("\nRace: {d} ms [{d} mm] -- {d}", .{ t, d, wins });
    }
    std.debug.print("\n\nResult: {d}\n", .{ result });
}

fn part2(input: []const u8) !void {
    std.debug.print("\n########## Part 2 ##########", .{});

    var time: u64 = undefined;
    var dist: u64 = undefined;

    var row_it = std.mem.tokenize(u8, input, "\n");

    // Time
    var time_row = try std.mem.replaceOwned(u8, allocator, row_it.next().?, " ", "");
    var time_it = std.mem.tokenize(u8, time_row, ":");
    _ = time_it.next().?;
    const time_number_str = time_it.next().?;
    time = std.fmt.parseInt(u64, time_number_str, 10) catch undefined;

    // Distance
    var dist_row = try std.mem.replaceOwned(u8, allocator, row_it.next().?, " ", "");
    var dist_it = std.mem.tokenize(u8, dist_row, ":");
    _ = dist_it.next().?;
    const dist_number_str = dist_it.next().?;
    dist = std.fmt.parseInt(u64, dist_number_str, 10) catch undefined;

    std.debug.print("\n{d}: {d}", .{time, dist});

    const wins = resolveRace(u64, time, dist);
    std.debug.print("\nRace: {d} ms [{d} mm] -- {d}", .{ time, dist, wins });
    std.debug.print("\n\nResult: {d}\n", .{ wins });
}

pub fn main() !void {
    const input = try puzzle_input.getPuzzleInput(allocator, 6);
    // const input = try puzzle_input.getPuzzleTestInput(allocator, 6);

    sw.start();
    try part1(input);
    const time_part1 = sw.stop();
    std.debug.print("\n{d:3} ms\n", .{time_part1});

    sw.start();
    try part2(input);
    const time_part2 = sw.stop();
    std.debug.print("\n{d:3} ms\n", .{time_part2});
}
