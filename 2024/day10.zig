const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 10;
const Allocator = std.mem.Allocator;
const log = std.log;

const Trail = struct {
    id: usize,
    height: u8,
    position: @Vector(2, usize),

    pub fn format(self: Trail, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("T {d} [{d}] → {d}", .{ self.id, self.position, self.height });
    }
};

const TrailMap = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,
    viz: [][]u8 = undefined,
    trails: std.ArrayList(Trail) = undefined,
    result_vector: @Vector(300, usize) = @splat(0),
    finished_trails: std.AutoHashMap(usize, std.ArrayList(@Vector(2, usize))) = undefined,
    find_distinct_trails: bool = false,

    pub fn init(self: *TrailMap, allocator: Allocator, row_it: *std.mem.SplitIterator(u8, .sequence)) !void {
        self.cols = row_it.peek().?.len;
        while (row_it.next()) |_| : (self.rows += 1) {}
        row_it.reset();

        self.buffer = try allocator.alloc([]u8, self.cols);
        self.viz = try allocator.alloc([]u8, self.cols);
        self.trails = std.ArrayList(Trail).init(allocator);
        self.finished_trails = std.AutoHashMap(usize, std.ArrayList(@Vector(2, usize))).init(allocator);

        var x: usize = 0;
        var zeroes: usize = 0;
        while (row_it.next()) |row| : (x += 1) {
            self.buffer[x] = try allocator.alloc(u8, self.rows);
            self.viz[x] = try allocator.alloc(u8, self.rows);
            for (0..self.rows) |y| {
                self.viz[x][y] = '.';
                if (!std.ascii.isDigit(row[y])) {
                    continue;
                }
                const number = try std.fmt.charToDigit(row[y], 10);
                self.buffer[x][y] = number;
                if (number == 0) {
                    const start_trail = Trail{
                        .id = zeroes,
                        .height = number, // 0 in the beginning
                        .position = @Vector(2, usize){ x, y },
                    };
                    try self.trails.append(start_trail);
                    try self.finished_trails.put(start_trail.id, std.ArrayList(@Vector(2, usize)).init(allocator));
                    self.viz[x][y] = '0';
                    zeroes += 1;
                }
            }
        }

        // log.info("{any}", .{self});
    }

    fn progress(self: *TrailMap, trail: *Trail) !void {
        self.setViz(trail.position[0], trail.position[1], std.fmt.digitToChar(trail.height, .lower));

        const offsets = [4]@Vector(2, isize){ .{ 0, -1 }, .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 } };
        for (offsets) |o| {
            const x = o[0];
            const y = o[1];

            const ox: usize = @intCast(@max(@as(isize, @intCast(trail.position[0])) +| x, 0));
            const oy: usize = @intCast(@max(@as(isize, @intCast(trail.position[1])) +| y, 0));
            const next_pos: @Vector(2, usize) = .{ ox, oy };

            if (ox < 0 or oy < 0 or ox >= self.cols or oy >= self.rows or
                (ox == trail.position[0] and oy == trail.position[1]))
            {
                continue;
            }
            // self.setViz(ox, oy, 'X');

            if (trail.height + 1 == self.buffer[ox][oy]) {
                const entry = self.finished_trails.getEntry(trail.id);
                var already_finished = false;

                if (!self.find_distinct_trails) {
                    for (entry.?.value_ptr.items) |p| {
                        already_finished = p[0] == next_pos[0] and p[1] == next_pos[1];
                        if (already_finished) break;
                    }
                }

                if (trail.height + 1 == 9 and !already_finished) {
                    try entry.?.value_ptr.append(next_pos);
                    self.setViz(ox, oy, '9');
                    self.result_vector[trail.id] += 1;
                } else {
                    try self.trails.append(Trail{
                        .id = trail.id,
                        .height = trail.height + 1,
                        .position = next_pos,
                    });
                }

                // log.info("{any}", .{self});
                // log.info("× Finished Trail positions: {any}", .{entry.?.value_ptr.items});
                // log.info("  →  {any}", .{next_pos});
                // log.info("  →  Already visited? {any}", .{already_finished});
                // log.info("× Result vector:\n{d}", .{self.result_vector});
                // log.info("\n\n", .{});
            }
        }
    }

    fn setViz(self: *TrailMap, x: usize, y: usize, v: u8) void {
        self.viz[x][y] = v;
    }

    pub fn solve(self: *TrailMap) !usize {
        while (self.trails.items.len > 0) {
            var next = self.trails.pop().?;
            try self.progress(&next);
        }
        const result: usize = @reduce(.Add, self.result_vector);
        return result;
    }

    pub fn format(self: TrailMap, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n\nMAP:", .{});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                if (val >= 0 and val <= 9) {
                    try writer.print("{s}{d}{s} ", .{ t.red, val, t.clear });
                } else {
                    try writer.print(". ", .{});
                }
            }
        }
        try writer.print("\n\nVIZ:", .{});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                const val = self.viz[x][y];
                if (std.ascii.isDigit(val)) {
                    try writer.print("{s}{c}{s} ", .{ t.red, val, t.clear });
                } else {
                    try writer.print("{c} ", .{val});
                }
            }
        }
        try writer.print("\n\nTRAILS:", .{});
        for (self.trails.items) |trail| {
            try writer.print("\n - {any}", .{trail});
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !TrailMap {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var row_it = std.mem.splitSequence(u8, trimmed, "\n");

    var map = TrailMap{};
    try map.init(allocator, &row_it);
    return map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    const result = try map.solve();

    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var map = try parseInput(allocator, input);
    map.find_distinct_trails = true;
    const result = try map.solve();

    std.debug.print("\nResult: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
