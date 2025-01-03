const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 25;
const Allocator = std.mem.Allocator;
const log = std.log;

const Kind = enum(u1) {
    LOCK,
    KEY,

    pub fn format(self: Kind, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .LOCK => try writer.print("LOCK", .{}),
            .KEY => try writer.print("KEY", .{}),
        }
    }
};

const Schematic = struct {
    kind: Kind,
    heights: []u8,

    pub fn format(self: Schematic, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n{any}\n", .{self.kind});
        for (0..5) |h| {
            try writer.print("{d},", .{self.heights[h]});
        }
    }
};

const KeyLocks = struct {
    keys: std.ArrayList(Schematic),
    locks: std.ArrayList(Schematic),

    pub fn solve(self: *KeyLocks) usize {
        var match_count: usize = 0;
        for (self.keys.items) |key| {
            for (self.locks.items) |lock| {
                var match: bool = true;
                for (0..key.heights.len) |i| {
                    const diff = key.heights[i] + lock.heights[i];
                    if (diff > 5) {
                        match = false;
                        break;
                    }
                }
                if (match)
                    match_count += 1;
            }
        }
        return match_count;
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !KeyLocks {
    const trimmed = std.mem.trimRight(u8, input, "\n");

    var keys = std.ArrayList(Schematic).init(allocator);
    var locks = std.ArrayList(Schematic).init(allocator);

    var lock_schematics_it = std.mem.splitSequence(u8, trimmed, "\n\n");
    while (lock_schematics_it.next()) |schematic_str| {
        log.info("\n{s}", .{schematic_str});

        var size = @Vector(2, usize){ 0, 0 };
        var schematic_it = std.mem.splitSequence(u8, schematic_str, "\n");
        size[0] = schematic_it.peek().?.len;
        while (schematic_it.next()) |_| size[1] += 1;
        schematic_it.reset();

        var schematic = Schematic{
            .kind = .LOCK,
            .heights = try allocator.alloc(u8, size[0]),
        };

        for (0..size[0]) |i| schematic.heights[i] = 0;

        var idx: usize = 0;
        while (schematic_it.next()) |row| : (idx += 1) {
            if (idx == 0 and std.mem.containsAtLeast(u8, row, size[0], "#")) {
                schematic.kind = .LOCK;
                continue;
            }
            if (idx == size[1] - 1 and std.mem.containsAtLeast(u8, row, size[0], "#")) {
                schematic.kind = .KEY;
                continue;
            }
            for (0..row.len) |v| {
                schematic.heights[v] += if (row[v] == '#') 1 else 0;
            }
        }

        switch (schematic.kind) {
            .KEY => try keys.append(schematic),
            .LOCK => try locks.append(schematic),
        }

        log.info("{d}", .{size});
        log.info("{any}", .{schematic});
    }

    return KeyLocks{ .locks = locks, .keys = keys };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var key_locks = try parseInput(allocator, input);
    const result = key_locks.solve();
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
