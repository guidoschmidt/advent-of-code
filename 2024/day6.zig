const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 6;
const Allocator = std.mem.Allocator;
const log = std.log;

const Dir = enum(u3) {
    UP,
    RIGHT,
    DOWN,
    LEFT,

    pub fn rotateRight(self: Dir) Dir {
        return @enumFromInt(@mod(@intFromEnum(self) + 1, 4));
    }

    pub fn value(self: Dir) @Vector(2, isize) {
        return switch (self) {
            .UP => .{ 0, -1 },
            .RIGHT => .{ 1, 0 },
            .DOWN => .{ 0, 1 },
            .LEFT => .{ -1, 0 },
        };
    }
};

const PathStep = struct {
    dir: Dir,
    pos: @Vector(2, isize),
};

const Map = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,
    path_buffer: [][]u8 = undefined,
    guard_pos: @Vector(2, isize) = undefined,
    guard_start_pos: @Vector(2, isize) = undefined,
    guard_dir: Dir = .UP,
    path: std.ArrayList(@Vector(2, isize)) = undefined,
    is_looped: bool = false,
    block_pos: @Vector(2, isize) = undefined,
    path_history: std.ArrayList(PathStep) = undefined,

    pub fn init(self: *Map, allocator: Allocator, row_it: *std.mem.SplitIterator(u8, .sequence)) !void {
        self.cols = row_it.peek().?.len;
        self.rows = 0;
        while (row_it.next()) |_| : (self.rows += 1) {}
        row_it.reset();

        var x: usize = 0;
        self.buffer = try allocator.alloc([]u8, self.cols);
        self.path_buffer = try allocator.alloc([]u8, self.cols);
        while (row_it.next()) |row| : (x += 1) {
            self.buffer[x] = try allocator.alloc(u8, self.rows);
            self.path_buffer[x] = try allocator.alloc(u8, self.rows);
            for (0..self.rows) |y| {
                self.buffer[x][y] = row[y];
                self.path_buffer[x][y] = row[y];
                if (row[y] == '^') {
                    self.guard_pos = .{ @intCast(y), @intCast(x) };
                    self.guard_start_pos = .{ @intCast(y), @intCast(x) };
                }
            }
        }

        self.path = std.ArrayList(@Vector(2, isize)).init(allocator);
        self.path_history = std.ArrayList(PathStep).init(allocator);
        // log.info("Guard @ {d} → {d}", .{ self.guard_pos, self.guard_dir.value() });
        // aoc.blockAskForNext();
    }

    fn moveGuard(self: *Map, check_loops: bool) !usize {
        var count: usize = 0;
        var rotation_count: usize = 0;
        while (true) {
            var next = self.guard_pos + self.guard_dir.value();
            if (next[0] < 0 or next[0] >= self.rows or
                next[1] < 0 or next[1] >= self.cols)
            {
                count += 1;
                self.is_looped = false;
                break;
            }
            if (self.get(next) == '#' or self.get(next) == 'O') {
                self.guard_dir = self.guard_dir.rotateRight();
                rotation_count += 1;
                next = self.guard_pos + self.guard_dir.value();
            }
            if (self.getPath(self.guard_pos) != 'X') {
                self.setPath(self.guard_pos, 'X');
                count += 1;
            }
            if (!check_loops and !self.alreadyStoredPath()) {
                try self.path.append(self.guard_pos);
            }

            // log.info(">>> {any} {any} ---> {any} : {any} [{d}]", .{ self.guard_pos, self.guard_dir, next, self.checkPathHistory(next, self.guard_dir), self.path_history.items.len });
            // log.info("{any}", .{self});
            if (check_loops) {
                try self.path_history.append(PathStep{
                    .dir = self.guard_dir,
                    .pos = self.guard_pos,
                });
            }
            if (check_loops and (self.checkPathHistory(next, self.guard_dir))) {
                self.is_looped = true;
                break;
            }
            self.guard_pos += self.guard_dir.value();
        }
        return count;
    }

    fn checkPathHistory(self: *Map, next: @Vector(2, isize), dir: Dir) bool {
        for (self.path_history.items) |path_step| {
            if (@reduce(.And, path_step.pos == next) and
                (path_step.dir == dir or dir == .RIGHT))
                return true;
        }
        return false;
    }

    fn alreadyStoredPath(self: *Map) bool {
        for (self.path.items) |path_pos| {
            if (@reduce(.And, path_pos == self.guard_pos)) return true;
        }
        return false;
    }

    fn reset(self: *Map) void {
        log.info("→ RESET", .{});
        self.path_history.clearAndFree();
        log.info("{d}", .{self.path_history.items.len});
        // aoc.blockAskForNext();
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                self.path_buffer[x][y] = self.buffer[x][y];
                if (self.buffer[x][y] == 'O') {
                    self.buffer[x][y] = '.';
                    self.path_buffer[x][y] = '.';
                }
                if (self.buffer[x][y] == '^') {
                    self.guard_pos = .{ @intCast(y), @intCast(x) };
                    self.buffer[x][y] = '^';
                    self.path_buffer[x][y] = '^';
                }
            }
        }
        self.guard_dir = .UP;
    }

    fn getPath(self: Map, pos: @Vector(2, isize)) u8 {
        return self.path_buffer[@intCast(pos[1])][@intCast(pos[0])];
    }

    fn setPath(self: Map, pos: @Vector(2, isize), v: u8) void {
        self.path_buffer[@intCast(pos[1])][@intCast(pos[0])] = v;
    }

    fn get(self: Map, pos: @Vector(2, isize)) u8 {
        return self.buffer[@intCast(pos[1])][@intCast(pos[0])];
    }

    fn set(self: Map, pos: @Vector(2, isize), v: u8) void {
        self.buffer[@intCast(pos[1])][@intCast(pos[0])] = v;
    }

    pub fn format(self: Map, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Guard: @ {any}", .{self.guard_pos});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                if (y == self.guard_pos[0] and x == self.guard_pos[1]) {
                    switch (self.guard_dir) {
                        .UP => try writer.print("{s}{c}{s}", .{ t.red, '^', t.clear }),
                        .RIGHT => try writer.print("{s}{c}{s}", .{ t.red, '>', t.clear }),
                        .DOWN => try writer.print("{s}{c}{s}", .{ t.red, 'v', t.clear }),
                        .LEFT => try writer.print("{s}{c}{s}", .{ t.red, '<', t.clear }),
                    }
                } else {
                    try writer.print("{c} ", .{self.buffer[x][y]});
                }
            }
        }
        // try writer.print("\n", .{});
        // for (0..self.cols) |x| {
        //     try writer.print("\n ", .{});
        //     for (0..self.rows) |y| {
        //         try writer.print("{c} ", .{self.path_buffer[x][y]});
        //     }
        // }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !Map {
    const cleaned = std.mem.trimRight(u8, input, "\n");
    var row_it = std.mem.split(u8, cleaned, "\n");

    var map = Map{};
    try map.init(allocator, &row_it);
    return map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    const result = try map.moveGuard(false);
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    _ = try map.moveGuard(false);
    map.reset();
    var looped_count: usize = 0;
    while (map.path.items.len > 0) {
        const next = map.path.pop();
        log.info("Next: {d}", .{next});
        map.set(next, 'O');
        _ = try map.moveGuard(true);
        // aoc.blockAskForNext();
        if (map.is_looped) {
            looped_count += 1;
        }
        map.reset();
        log.info("...{d} loops, {d} to go", .{ looped_count, map.path.items.len });
    }
    std.debug.print("\nResult: {d}", .{looped_count});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
