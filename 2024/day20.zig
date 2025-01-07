const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");
const VectorSet = @import("./VectorSet.zig").VectorSet;

const DAY: u8 = 20;
const Allocator = std.mem.Allocator;
const log = std.log;
const cheat_savings_threshold: usize = 100;

const Racetrack = struct {
    size: @Vector(2, usize) = .{ 0, 0 },
    start: @Vector(2, usize) = undefined,
    end: @Vector(2, usize) = undefined,
    buffer: [][]u8 = undefined,
    track: std.ArrayList(@Vector(2, usize)) = undefined,

    pub fn init(allocator: Allocator, input: []const u8) !Racetrack {
        var instance = Racetrack{};

        const trimmed = std.mem.trimRight(u8, input, "\n");
        var it = std.mem.splitSequence(u8, trimmed, "\n");
        instance.size[0] = it.peek().?.len;
        while (it.next()) |_| : (instance.size[1] += 1) {}
        it.reset();

        instance.buffer = try allocator.alloc([]u8, instance.size[1]);
        var y: usize = 0;
        while (it.next()) |row| : (y += 1) {
            instance.buffer[y] = try allocator.alloc(u8, instance.size[0]);
            for (0..row.len) |x| {
                const v = row[x];
                if (v == 'S') {
                    instance.start = .{ x, y };
                }
                if (v == 'E') {
                    instance.end = .{ x, y };
                }
                instance.buffer[y][x] = v;
            }
        }

        return instance;
    }

    pub fn onTrack(self: *Racetrack, p: @Vector(2, usize)) ?usize {
        for (0..self.track.items.len) |i| {
            const tp = self.track.items[i];
            if (@reduce(.And, tp == p)) return i;
        }
        return null;
    }

    pub fn inBounds(self: *Racetrack, p: @Vector(2, isize)) bool {
        return (p[0] >= 0 and p[1] >= 0 and p[0] < self.size[0] and p[1] < self.size[1]);
    }

    pub fn findCheats(self: *Racetrack, allocator: Allocator) !usize {
        var processed = VectorSet(2, usize).init(allocator);

        var cheat_save_list = std.AutoHashMap(usize, usize).init(allocator);

        for (self.track.items) |p| {
            const start = p;
            const start_idx = self.onTrack(start).?;
            const dirs = [_]@Vector(2, isize){
                @Vector(2, isize){ -1, 0 },
                @Vector(2, isize){ 0, 1 },
                @Vector(2, isize){ 1, 0 },
                @Vector(2, isize){ 0, -1 },
            };
            for (dirs) |d| {
                const n = @as(@Vector(2, isize), @intCast(start)) + d;
                if (!self.inBounds(n)) continue;
                const neigbour = @as(@Vector(2, usize), @intCast(n));
                if (processed.contains(neigbour)) continue;
                // Existing track
                if (!(self.onTrack(neigbour) == null)) continue;
                // Found wall
                if (self.buffer[neigbour[1]][neigbour[0]] == '#') {
                    // --- Visualize neighbour 'pixel'
                    // const before = self.buffer[neigbour[1]][neigbour[0]];
                    // self.buffer[neigbour[1]][neigbour[0]] = 'N';
                    // self.animate();
                    // aoc.blockAskForNext();
                    // self.buffer[neigbour[1]][neigbour[0]] = before;

                    const back_on_track = @as(@Vector(2, isize), @intCast(n + d));
                    if (!self.inBounds(back_on_track)) continue;

                    if (self.onTrack(@intCast(back_on_track))) |idx| {
                        log.info("{d} -> # {d} -> {d} [{d}]", .{ start, neigbour, back_on_track, idx });
                        const track_length_to_cheat: usize = start_idx + 1;
                        const track_length_rest: usize = self.track.items.len - idx;
                        const track_length_with_cheat: usize = track_length_to_cheat + track_length_rest;
                        const saves = (self.track.items.len - 1) - track_length_with_cheat;
                        log.info("   >>> Cheat saves {d} picoseconds [shortened length: {d} / {d}]", .{ saves, track_length_to_cheat, self.track.items.len });

                        const prev = cheat_save_list.get(saves) orelse 0;
                        try cheat_save_list.put(saves, prev + 1);

                        // --- Visualize cheat path
                        // self.buffer[neigbour[1]][neigbour[0]] = 'C';
                        // self.animate();
                        // self.buffer[neigbour[1]][neigbour[0]] = '#';
                        // aoc.blockAskForNext();

                        try processed.insert(neigbour);
                    }
                }
            }
        }
        // self.animate();

        var it = cheat_save_list.keyIterator();
        var cheats: [][2]usize = try allocator.alloc([2]usize, cheat_save_list.count());
        var i: usize = 0;
        while (it.next()) |cheat_saving| : (i += 1) {
            const count = cheat_save_list.get(cheat_saving.*) orelse 0;
            cheats[i][0] = count;
            cheats[i][1] = cheat_saving.*;
        }

        std.mem.sort([2]usize, cheats, {}, comptime struct {
            pub fn f(_: void, a: [2]usize, b: [2]usize) bool {
                return a[1] < b[1];
            }
        }.f);

        var cheats_savings: usize = 0;
        for (cheats) |cheat| {
            if (cheat[1] >= cheat_savings_threshold) cheats_savings += cheat[0];
            log.info("There are {d} cheats that save {d} picoseconds.", .{
                cheat[0],
                cheat[1],
            });
        }

        return cheats_savings;
    }

    pub fn findTrack(self: *Racetrack, allocator: Allocator, start: @Vector(2, usize)) !usize {
        var pos_list = std.ArrayList(@Vector(2, usize)).init(allocator);
        try pos_list.append(start);

        self.track = std.ArrayList(@Vector(2, usize)).init(allocator);

        while (pos_list.items.len > 0) {
            const current = pos_list.pop();

            if (!(@reduce(.And, current == self.start) or @reduce(.And, current == self.end))) {
                self.buffer[current[1]][current[0]] = 'X';
            }
            try self.track.append(current);

            // End was reached
            if (@reduce(.And, current == self.end)) {
                break;
            }

            // Visualize track finding
            // self.animate();

            const neighbours = [4]@Vector(2, usize){
                @intCast(@as(@Vector(2, isize), @intCast(current)) +| @Vector(2, isize){ -1, 0 }),
                @intCast(@as(@Vector(2, isize), @intCast(current)) +| @Vector(2, isize){ 0, -1 }),
                @intCast(@as(@Vector(2, isize), @intCast(current)) +| @Vector(2, isize){ 1, 0 }),
                @intCast(@as(@Vector(2, isize), @intCast(current)) +| @Vector(2, isize){ 0, 1 }),
            };
            for (neighbours) |n| {
                if (self.buffer[n[1]][n[0]] == '.') {
                    try pos_list.append(n);
                }
            }
        }
        try self.track.append(self.end);

        return self.track.items.len;
    }

    pub fn format(self: Racetrack, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.size[0]) |x| {
            try writer.print("\n", .{});
            for (0..self.size[1]) |y| {
                const val = self.buffer[x][y];
                switch (val) {
                    '#' => try writer.print("{s}{c} {s}", .{ t.bg_white, ' ', t.clear }),
                    '.' => try writer.print("{s}{c} {s}", .{ t.dark_gray, val, t.clear }),
                    'S', 'E' => try writer.print("{s}{c} {s}", .{ t.yellow, val, t.clear }),
                    else => try writer.print("{c} ", .{val}),
                }
                try writer.print("{s}", .{t.clear});
            }
        }
        try writer.print("\n\n ", .{});
    }

    pub fn animate(self: Racetrack) void {
        for (0..self.size[0]) |x| {
            for (0..self.size[1]) |y| {
                std.debug.print(t.yx, .{ 2 + y, 2 + x * 2 });
                const v = self.buffer[y][x];
                switch (v) {
                    '#' => std.debug.print("{s}{c} {s}", .{ t.bg_white, ' ', t.clear }),
                    'S', 'E' => std.debug.print("{s}{c} {s}", .{ t.yellow, v, t.clear }),
                    'X' => std.debug.print("{s}{c} {s}", .{ t.bg_red, ' ', t.clear }),
                    'C' => std.debug.print("{s}{c} {s}", .{ t.bg_cyan, 'C', t.clear }),
                    'N' => std.debug.print("{s}{c} {s}", .{ t.bg_red, 'N', t.clear }),
                    else => std.debug.print("{s}{c} {s}", .{ t.dark_gray, v, t.clear }),
                }
            }
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !Racetrack {
    return try Racetrack.init(allocator, input);
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var racetrack = try parseInput(allocator, input);

    std.debug.print(t.clear_screen, .{});
    std.debug.print(t.hide_cursor, .{});

    const refrence_duration = try racetrack.findTrack(allocator, racetrack.start);
    log.info("Duration: {d} ps", .{refrence_duration - 1});
    const cheat_count = try racetrack.findCheats(allocator);

    std.debug.print("\nResult: {d}", .{cheat_count});
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
