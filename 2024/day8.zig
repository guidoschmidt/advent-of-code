const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 8;
const Allocator = std.mem.Allocator;
const log = std.log;
const antinode_char: isize = @intCast('#');

const AntennaPair = struct {
    a: @Vector(3, isize),
    b: @Vector(3, isize),
};

const AntennaMap = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,
    viz: [][]u8 = undefined,
    antenna_positions: std.ArrayList(@Vector(3, isize)) = undefined,

    pub fn init(self: *AntennaMap, allocator: Allocator, row_it: *std.mem.SplitIterator(u8, .sequence)) !void {
        self.cols = row_it.peek().?.len;
        self.rows = 0;
        while (row_it.next()) |_| : (self.rows += 1) {}
        row_it.reset();

        self.antenna_positions = std.ArrayList(@Vector(3, isize)).init(allocator);

        var y: usize = 0;
        self.buffer = try allocator.alloc([]u8, self.cols);
        self.viz = try allocator.alloc([]u8, self.cols);
        while (row_it.next()) |row| : (y += 1) {
            self.buffer[y] = try allocator.alloc(u8, self.rows);
            self.viz[y] = try allocator.alloc(u8, self.rows);
            for (0..self.rows) |x| {
                if (row[x] != '.') {
                    const freq = row[x];
                    try self.antenna_positions.append(.{ @intCast(freq), @intCast(y), @intCast(x) });
                }
                self.buffer[y][x] = row[x];
                self.viz[y][x] = '.';
            }
        }
    }

    fn get(self: AntennaMap, pos: @Vector(2, isize)) u8 {
        return self.buffer[@intCast(pos[1])][@intCast(pos[0])];
    }

    pub fn format(self: AntennaMap, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        // try writer.print("\nAntennas:", .{});
        // for (self.antenna_positions.items) |antenna| {
        //     try writer.print("\n{c} @ [{d}, {d}]", .{ @as(u8, @intCast(antenna[0])), antenna[1], antenna[2] });
        // }

        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                if (val == '.')
                    try writer.print("{c}", .{val});
                if (val != '.')
                    try writer.print("{s}{c}{s}", .{ t.red, val, t.clear });
            }
        }

        try writer.print("\n", .{});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                try writer.print("{c}", .{self.viz[x][y]});
            }
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !AntennaMap {
    const trimmed = std.mem.trim(u8, input, "\n");
    var row_it = std.mem.splitSequence(u8, trimmed, "\n");
    var map = AntennaMap{};
    try map.init(allocator, &row_it);
    return map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    // log.info("# Antennas: {d}", .{map.antenna_positions.items.len});

    const antennas = try map.antenna_positions.clone();
    var antenna_pairs = std.ArrayList(AntennaPair).init(allocator);

    while (map.antenna_positions.items.len > 0) {
        const a = map.antenna_positions.pop();
        for (antennas.items) |b| {
            if (a.?[0] == b[0])
                try antenna_pairs.append(AntennaPair{ .a = a.?, .b = b });
        }
    }

    // for (antenna_pairs.items) |pair| {
    //     log.info("A {c} @ [{d}, {d}] <--> {c} @ [{d}, {d}] B", .{ @as(u8, @intCast(pair.a[0])), pair.a[1], pair.a[2], @as(u8, @intCast(pair.b[0])), pair.b[1], pair.b[2] });
    // }

    for (antenna_pairs.items) |pair| {
        // Don't use antennas with itself
        if (pair.a[1] == pair.b[1] and pair.a[2] == pair.b[2]) continue;
        const distance: @Vector(3, isize) = @intCast(pair.b - pair.a);
        // log.info("{c}: [{d}, {d}] <--> {c}: [{d}, {d}] -- [{d}]", .{ @as(u8, @intCast(pair.a[0])), pair.a[1], pair.a[2], @as(u8, @intCast(pair.b[0])), pair.b[1], pair.b[2], distance });

        var antinode_a = @Vector(3, isize){ antinode_char, pair.a[1], pair.a[2] };
        var antinode_b = @Vector(3, isize){ antinode_char, pair.b[1], pair.b[2] };
        if (pair.a[1] < pair.b[1] or pair.a[2] < pair.b[2]) {
            antinode_a -= distance;
            antinode_b += distance;
        } else {
            antinode_a += distance;
            antinode_b -= distance;
        }

        if (map.viz[@intCast(pair.a[1])][@intCast(pair.a[2])] == '.')
            map.viz[@intCast(pair.a[1])][@intCast(pair.a[2])] = @intCast(pair.a[0]);

        if (map.viz[@intCast(pair.b[1])][@intCast(pair.b[2])] == '.')
            map.viz[@intCast(pair.b[1])][@intCast(pair.b[2])] = @intCast(pair.b[0]);

        if (!(antinode_a[1] < 0 or antinode_a[1] >= map.cols or
            antinode_a[2] < 0 or antinode_a[2] >= map.rows))
        {
            if (map.viz[@intCast(antinode_a[1])][@intCast(antinode_a[2])] == '.' or
                map.buffer[@intCast(antinode_a[1])][@intCast(antinode_a[2])] != pair.a[0])
            {
                map.viz[@intCast(antinode_a[1])][@intCast(antinode_a[2])] = '#';
            }
        }

        if (!(antinode_b[1] < 0 or antinode_b[1] >= map.cols or
            antinode_b[2] < 0 or antinode_b[2] >= map.rows))
        {
            if (map.viz[@intCast(antinode_b[1])][@intCast(antinode_b[2])] == '.' or
                map.buffer[@intCast(antinode_b[1])][@intCast(antinode_b[2])] != pair.a[0])
            {
                map.viz[@intCast(antinode_b[1])][@intCast(antinode_b[2])] = '#';
            }
        }

        // log.info("{any}", .{map});
        // aoc.blockAskForNext();
    }

    var antinode_count: usize = 0;
    for (0..map.cols) |x| {
        for (0..map.rows) |y| {
            if (map.viz[x][y] != '#') {
                antinode_count += 1;
            }
        }
    }

    std.debug.print("\nResult: {d}", .{antinode_count});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    log.info("# Antennas: {d}", .{map.antenna_positions.items.len});

    const antennas = try map.antenna_positions.clone();
    var antenna_pairs = std.ArrayList(AntennaPair).init(allocator);

    while (map.antenna_positions.items.len > 0) {
        const a = map.antenna_positions.pop();
        for (antennas.items) |b| {
            if (a.?[0] == b[0])
                try antenna_pairs.append(AntennaPair{ .a = a.?, .b = b });
        }
    }

    for (antenna_pairs.items) |pair| {
        if (pair.a[1] == pair.b[1] and pair.a[2] == pair.b[2]) continue;
        const distance: @Vector(3, isize) = @intCast(pair.b - pair.a);

        var s: usize = 1;
        while (s <= @max(map.rows, map.cols)) {
            const s_vec: @Vector(3, isize) = @splat(@as(isize, @intCast(s)));
            log.info("{d}: DIST [{d}] -- [{d} x {d}]", .{ s, s_vec[1], map.rows, map.cols });
            var antinode_a = @Vector(3, isize){ antinode_char, pair.a[1], pair.a[2] };
            var antinode_b = @Vector(3, isize){ antinode_char, pair.b[1], pair.b[2] };
            if (pair.a[1] < pair.b[1] or pair.a[2] < pair.b[2]) {
                antinode_a -= distance * s_vec;
                antinode_b += distance * s_vec;
            } else {
                antinode_a += distance * s_vec;
                antinode_b -= distance * s_vec;
            }

            if (map.viz[@intCast(pair.a[1])][@intCast(pair.a[2])] == '.')
                map.viz[@intCast(pair.a[1])][@intCast(pair.a[2])] = @intCast(pair.a[0]);

            if (map.viz[@intCast(pair.b[1])][@intCast(pair.b[2])] == '.')
                map.viz[@intCast(pair.b[1])][@intCast(pair.b[2])] = @intCast(pair.b[0]);

            if (!(antinode_a[1] < 0 or antinode_a[1] >= map.cols or
                antinode_a[2] < 0 or antinode_a[2] >= map.rows))
            {
                map.viz[@intCast(antinode_a[1])][@intCast(antinode_a[2])] = '#';
            }

            if (!(antinode_b[1] < 0 or antinode_b[1] >= map.cols or
                antinode_b[2] < 0 or antinode_b[2] >= map.rows))
            {
                map.viz[@intCast(antinode_b[1])][@intCast(antinode_b[2])] = '#';
            }

            s += 1;
        }
        log.info("{any}", .{map});
    }

    var antinode_count: usize = 0;
    for (0..map.cols) |x| {
        for (0..map.rows) |y| {
            if (map.viz[x][y] != '.') {
                antinode_count += 1;
            }
        }
    }

    std.debug.print("\nResult: {d}", .{antinode_count});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
