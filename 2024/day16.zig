const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 16;
const Allocator = std.mem.Allocator;
const log = std.log;

const START = 'S';
const END = 'E';

const ParseResult = struct {
    maze: Maze,
    reindeer: Reindeer,
};

const Dir = enum(i3) {
    N = 0,
    E = 1,
    S = 2,
    W = 3,

    pub fn char(self: Dir) u8 {
        return switch (self) {
            .N => '^',
            .E => '>',
            .S => 'v',
            .W => '<',
        };
    }

    pub fn rotate(self: *Dir, dir: isize) void {
        var v = @intFromEnum(self.*) + dir;
        v = @mod(v, 4);
        if (v == -1) {
            v = 0;
        }
        self.* = @enumFromInt(v);
    }
};

const Reindeer = struct {
    pos: @Vector(2, isize) = .{ 0, 0 },
    dir: Dir = .E,
};

const Maze = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,
    flood_fill_buffer: [][]isize = undefined,

    start: @Vector(2, usize) = undefined,
    end: @Vector(2, usize) = undefined,

    pub fn init(allocator: Allocator, rows: usize, cols: usize) !Maze {
        var instance = Maze{};
        instance.rows = rows;
        instance.cols = cols;

        instance.buffer = try allocator.alloc([]u8, instance.cols);
        instance.flood_fill_buffer = try allocator.alloc([]isize, instance.cols);
        for (0..instance.cols) |x| {
            instance.buffer[x] = try allocator.alloc(u8, instance.rows);
            instance.flood_fill_buffer[x] = try allocator.alloc(isize, instance.rows);
            for (0..instance.rows) |y| {
                instance.buffer[x][y] = '.';
                instance.flood_fill_buffer[x][y] = -1;
            }
        }
        return instance;
    }

    pub fn set(self: *Maze, pos: @Vector(2, usize), val: u8) void {
        self.buffer[pos[1]][pos[0]] = val;
    }

    pub fn format(self: Maze, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.cols) |x| {
            try writer.print("\n", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                switch (val) {
                    START => try writer.print("{s}{c}", .{ t.yellow, val }),
                    END => try writer.print("{s}{c}", .{ t.green, val }),
                    '#' => try writer.print("{s}{c}", .{ t.bg_red, val }),
                    '.' => try writer.print("{s}{c}", .{ t.dark_gray, val }),
                    '^', '>', 'v', '<' => try writer.print("{s}{c}", .{ t.yellow, val }),
                    else => try writer.print("{c}", .{val}),
                }
                try writer.print(" {s}", .{t.clear});
            }
        }
        try writer.print("\n ", .{});
        for (0..self.cols) |x| {
            try writer.print("\n", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                const fval = self.flood_fill_buffer[x][y];
                if (val == '#') {
                    try writer.print("{s}{c: <6}{s}", .{ t.bg_red, ' ', t.clear });
                }
                if (val != '#') {
                    try writer.print("{d: >6}", .{fval});
                }
            }
        }
        try writer.print("\n ", .{});
    }

    pub fn floodFill(self: *Maze, allocator: Allocator) !usize {
        var stack = std.ArrayList(@Vector(4, usize)).init(allocator);
        defer stack.deinit();
        try stack.append(@Vector(4, usize){ self.end[0], self.end[1], @intFromEnum(Dir.S), 0 });
        self.flood_fill_buffer[self.end[1]][self.end[0]] = 0;
        while (stack.items.len > 0) {
            std.mem.sort(@Vector(4, usize), stack.items, {}, comptime struct {
                pub fn f(_: void, a: @Vector(4, usize), b: @Vector(4, usize)) bool {
                    return a[3] > b[3];
                }
            }.f);

            const pos = stack.pop();
            const x: usize = pos[0];
            const y: usize = pos[1];
            const dir: usize = pos[2];
            const score: usize = pos[3];

            if (@reduce(.And, @Vector(2, usize){ x, y } == self.start)) {
                return score;
            }

            self.flood_fill_buffer[y][x] = @intCast(score);

            const offsets = [4]@Vector(2, isize){ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
            const dirs = [4]Dir{ .N, .E, .S, .W };
            for (0..offsets.len) |idx| {
                const o = offsets[idx];
                const next = @Vector(2, isize){ @intCast(x), @intCast(y) } + o;
                const ox: usize = @intCast(next[0]);
                const oy: usize = @intCast(next[1]);

                if (self.flood_fill_buffer[oy][ox] < 0 and self.buffer[oy][ox] != '#') {
                    var next_score = score + 1;
                    if (dir != @intFromEnum(dirs[idx]))
                        next_score += 1000;
                    try stack.append(.{ ox, oy, @intCast(@intFromEnum(dirs[idx])), next_score });
                }
            }
        }

        return 0;
    }

    pub fn findPath(self: *Maze, reindeer: *Reindeer) usize {
        var score: usize = 0;
        reindeer.pos = @intCast(self.start);
        while (true) {
            self.buffer[@intCast(@max(0, reindeer.pos[1]))][@intCast(@max(0, reindeer.pos[0]))] = reindeer.dir.char();

            if (@reduce(.And, reindeer.pos == @as(@Vector(2, isize), @intCast(self.end)))) {
                reindeer.pos = @intCast(self.end);
                score += 1;
                break;
            }

            const offsets = [4]@Vector(2, isize){
                .{ -1, 0 },
                .{ 1, 0 },
                .{ 0, -1 },
                .{ 0, 1 },
            };
            const dirs = [4]Dir{ .W, .E, .N, .S };
            var next: @Vector(2, isize) = reindeer.pos;
            var next_dir: Dir = reindeer.dir;
            var next_ff_score = self.flood_fill_buffer[@intCast(next[1])][@intCast(next[0])];
            for (0..offsets.len) |i| {
                const o = offsets[i];
                const local_next = @max(reindeer.pos + o, @Vector(2, isize){ 0, 0 });
                const local_dir = dirs[i];
                if (self.buffer[@intCast(local_next[1])][@intCast(local_next[0])] == '#') continue;
                const local_ff_score = self.flood_fill_buffer[@intCast(local_next[1])][@intCast(local_next[0])];

                if (local_ff_score <= next_ff_score) {
                    next = local_next;
                    next_ff_score = local_ff_score;
                    next_dir = local_dir;
                }
            }
            score += Maze.calcScore(1, @abs(@intFromEnum(reindeer.dir) - @intFromEnum(next_dir)));
            reindeer.dir = next_dir;
            reindeer.pos = next;
        }
        return score;
    }

    fn calcScore(step: usize, rot: u3) usize {
        return step + 1000 * @as(usize, @intCast(rot));
    }

    pub fn animate(self: *Maze) void {
        std.debug.print("{s}", .{t.hide_cursor});
        const w = 3;
        for (0..self.rows) |x| {
            for (0..self.cols) |y| {
                std.debug.print("\x1B[{d};{d}H", .{ 2 + y, 2 + x * w });
                const vb = self.buffer[y][x];
                const vf = self.flood_fill_buffer[y][x];
                if (vb != '#') {
                    std.debug.print("{d: >3}", .{vf});
                } else {
                    std.debug.print("{s}{c: ^3}{s}", .{ t.bg_red, '#', t.clear });
                }
            }
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var split_it = std.mem.splitSequence(u8, trimmed, "\n");

    // Reindeer
    var reindeer = Reindeer{};

    // Maze
    var rows: usize = 0;
    const cols: usize = split_it.peek().?.len;
    while (split_it.next()) |_| rows += 1;
    split_it.reset();
    var maze = try Maze.init(allocator, rows, cols);
    var y: usize = 0;
    while (split_it.next()) |row| : (y += 1) {
        for (0..row.len) |x| {
            const val = row[x];
            const pos = @Vector(2, usize){ x, y };
            if (val == START) {
                maze.start = pos;
                reindeer.pos = @intCast(maze.start);
            }
            if (val == END) {
                maze.end = pos;
            }
            maze.set(pos, row[x]);
        }
    }

    return ParseResult{ .maze = maze, .reindeer = reindeer };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var parsed = try parseInput(allocator, input);
    log.info("{any}", .{parsed.reindeer});
    log.info("{any}", .{parsed.maze});

    const result = try parsed.maze.floodFill(allocator);
    // const result = parsed.maze.findPath(&parsed.reindeer);
    log.info("{any}", .{parsed.maze});

    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
