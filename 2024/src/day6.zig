const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");
const VectorSet = @import("datastructures").VectorSet;

const DAY: u8 = 6;
const Allocator = std.mem.Allocator;
const log = std.log;

const Dir = enum(u3) {
    UP,
    RIGHT,
    DOWN,
    LEFT,

    pub fn turnRight(self: Dir) Dir {
        return @enumFromInt(@mod(@intFromEnum(self) + 1, 4));
    }

    pub fn value(self: Dir) @Vector(2, isize) {
        return switch (self) {
            .UP => .{ -1, 0 },
            .RIGHT => .{ 0, 1 },
            .DOWN => .{ 1, 0 },
            .LEFT => .{ 0, -1 },
        };
    }
};

const GuardResult = struct {
    path_visited: VectorSet(2, isize),
    is_looped: bool,
};

const Map = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    visited: VectorSet(2, isize) = undefined,

    buffer: [][]u8 = undefined,

    guard: @Vector(2, isize) = undefined,
    dir: Dir = .UP,

    pub fn init(allocator: Allocator, input: []const u8) !Map {
        var instance = Map{};

        const cleaned = std.mem.trimRight(u8, input, "\n");
        var row_it = std.mem.splitSequence(u8, cleaned, "\n");

        instance.cols = row_it.peek().?.len;
        instance.buffer = try allocator.alloc([]u8, instance.cols);
        while (row_it.next()) |_| : (instance.rows += 1) {}
        row_it.reset();

        instance.visited = VectorSet(2, isize).init(allocator);

        var x: usize = 0;
        instance.buffer = try allocator.alloc([]u8, instance.cols);
        while (row_it.next()) |row| : (x += 1) {
            instance.buffer[x] = try allocator.alloc(u8, instance.rows);
            for (0..instance.rows) |y| {
                if (row[y] == '^') {
                    instance.guard = .{ @intCast(x), @intCast(y) };
                    instance.buffer[x][y] = row[y];
                } else {
                    instance.buffer[x][y] = row[y];
                }
            }
        }

        return instance;
    }

    pub fn moveGuard(self: *Map, allocator: Allocator) !GuardResult {
        var path = VectorSet(2, isize).init(allocator);

        var history = VectorSet(3, isize).init(allocator);

        // Starting position
        try self.visited.insert(self.guard);

        var is_looped: bool = false;
        while (true) {
            // self.animate();
            // log.info("{s}", .{self});
            // aoc.blockAskForNext();

            const next = self.guard + self.dir.value();
            if (next[0] < 0 or next[0] >= self.cols or
                next[1] < 0 or next[1] >= self.rows)
            {
                // Did exit the map
                break;
            }

            if (self.buffer[@intCast(next[0])][@intCast(next[1])] == '#' or
                self.buffer[@intCast(next[0])][@intCast(next[1])] == 'O')
            {
                // Turn right on obstacles
                self.dir = self.dir.turnRight();
                continue;
            }

            self.guard = next;
            try self.visited.insert(self.guard);
            try path.insert(self.guard);

            if (history.contains(.{ self.guard[0], self.guard[1], @intFromEnum(self.dir) })) {
                is_looped = true;
                break;
            }
            try history.insert(.{ self.guard[0], self.guard[1], @intFromEnum(self.dir) });
        }

        return GuardResult{
            .is_looped = is_looped,
            .path_visited = path,
        };
    }

    pub fn reset(self: *Map, guard_start: @Vector(2, isize)) void {
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                if (self.buffer[x][y] == 'O') {
                    self.buffer[x][y] = '.';
                }
            }
        }
        self.guard = guard_start;
        self.dir = .UP;
    }

    pub fn animate(self: Map) void {
        const offset: @Vector(2, usize) = .{ 4, 4 };
        std.debug.print(t.hide_cursor, .{});
        std.debug.print(t.clear_screen, .{});
        for (0..self.cols) |y| {
            for (0..self.rows) |x| {
                std.debug.print(t.yx, .{ offset[0] + y, offset[1] + x * 2 });
                if (self.guard[0] == y and self.guard[1] == x) {
                    std.debug.print("{s}@ {s} ", .{ t.yellow, t.clear });
                    continue;
                }
                const v = self.buffer[y][x];
                switch (v) {
                    '#' => std.debug.print("{s}{c}{s}", .{ t.red, v, t.clear }),
                    'O' => std.debug.print("{s}{c}{s}", .{ t.white, v, t.clear }),
                    '.' => std.debug.print("{s}{c}{s}", .{ t.dark_gray, v, t.clear }),
                    else => std.debug.print("{s}{c}{s}", .{ t.blue, v, t.clear }),
                }
            }
        }
        std.time.sleep(std.time.ns_per_ms * 16);
    }

    pub fn format(self: Map, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n", .{});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                if (self.guard[0] == x and self.guard[1] == y) {
                    try writer.print("{s}{c}{s} ", .{ t.yellow, '@', t.clear });
                    continue;
                }
                const v = self.buffer[x][y];
                switch (v) {
                    '.' => try writer.print("{s}{c}{s} ", .{ t.dark_gray, v, t.clear }),
                    '#' => try writer.print("{s}{c}{s} ", .{ t.red, v, t.clear }),
                    'O' => try writer.print("{s}{c}{s} ", .{ t.white, v, t.clear }),
                    else => try writer.print("{c} ", .{v}),
                }
                // }
            }
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !Map {
    const map = try Map.init(allocator, input);
    return map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    _ = try map.moveGuard(allocator);
    std.debug.print("\nResult: {d}", .{map.visited.count()});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    const guard_start = map.guard;
    var result = try map.moveGuard(allocator);

    // Remove the guards starting position
    _ = result.path_visited.remove(guard_start);

    var looped_count: usize = 0;
    var path_it = result.path_visited.iterator();
    var i: usize = 0;
    var progress: f32 = 0;
    while (path_it.next()) |pos| : (i += 1) {
        progress = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(result.path_visited.count()));
        std.debug.print("\r", .{});
        std.debug.print(" {d:.0} % ", .{@ceil(progress * 100)});
        for (0..@as(usize, @intFromFloat(progress * 100))) |_| {
            std.debug.print("▓", .{});
        }

        map.reset(guard_start);
        map.buffer[@intCast(pos[0])][@intCast(pos[1])] = 'O';
        const inner_result = try map.moveGuard(allocator);
        if (inner_result.is_looped)
            looped_count += 1;
    }
    std.debug.print("\nResult: {d}", .{looped_count});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
