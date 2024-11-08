const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

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

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var times = std.ArrayList(u32).init(allocator);
    var dists = std.ArrayList(u32).init(allocator);

    var row_it = std.mem.tokenize(u8, input, "\n");
    while(row_it.next()) |r| {
        var val_it = std.mem.tokenize(u8, r, " ");
        const col = val_it.next().?;
        while(val_it.next()) |v| {
            if (std.mem.eql(u8, col, "Time:")) {
                const number = std.fmt.parseInt(u32, v, 10) catch continue;
                times.append(number) catch {
                    std.log.err("\nCould not append {d} to times ArrayList", .{ number });
                };
            }
            if (std.mem.eql(u8, col, "Distance:")) {
                const number = std.fmt.parseInt(u32, v, 10) catch continue;
                dists.append(number) catch {
                    std.log.err("\nCould not append {d} to dists ArrayList", .{ number });
                };
            }
        }
    }

    var result: u32 = 1;
    for (times.items, dists.items) |t, d| {
        const wins = resolveRace(u32, t, d);
        result *= wins;
        std.debug.print("\nRace: {d} ms [{d} mm] -- {d}", .{ t, d, wins });
    }
    std.debug.print("\n\nResult: {d}", .{ result });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var time: u64 = undefined;
    var dist: u64 = undefined;

    var row_it = std.mem.tokenize(u8, input, "\n");

    // Time
    const time_row = std.mem.replaceOwned(u8, allocator, row_it.next().?, " ", "") catch ""; 
    var time_it = std.mem.tokenize(u8, time_row, ":");
    _ = time_it.next().?;
    const time_number_str = time_it.next().?;
    time = std.fmt.parseInt(u64, time_number_str, 10) catch undefined;

    // Distance
    const dist_row = std.mem.replaceOwned(u8, allocator, row_it.next().?, " ", "") catch "";
    var dist_it = std.mem.tokenize(u8, dist_row, ":");
    _ = dist_it.next().?;
    const dist_number_str = dist_it.next().?;
    dist = std.fmt.parseInt(u64, dist_number_str, 10) catch undefined;

    std.debug.print("\n{d}: {d}", .{time, dist});

    const wins = resolveRace(u64, time, dist);
    std.debug.print("\nRace: {d} ms [{d} mm] -- {d}", .{ time, dist, wins });
    std.debug.print("\n\nResult: {d}", .{ wins });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try aoc.runPart(allocator, 2023, 6, .PUZZLE, part1);
    try aoc.runPart(allocator, 2023, 6, .PUZZLE, part2);
}
