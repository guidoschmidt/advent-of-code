const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

const rng_gen = std.rand.DefaultPrng;
var rng = rng_gen.init(0);

const EXPANDING_STEPS_PART1 = 1;
const EXPANDING_STEPS_PART2 = 1000000 - 1;

const Pos = struct {
    x: usize,
    y: usize,

    pub fn format(self: Pos, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("{d} x {d}", .{ self.x, self.y });
    }
};

const Map = struct {
    cols: usize = undefined,
    rows: usize = undefined,
    buffer: std.ArrayList(u8) = undefined,
    galaxies: std.ArrayList(Pos) = undefined,

    pub fn init(self: *Map, allocator: Allocator, cols: usize, rows: usize) void {
        self.cols = cols;
        self.rows = rows;
        self.buffer = std.ArrayList(u8).init(allocator);
        self.buffer.items = allocator.alloc(u8, self.cols * self.rows) catch unreachable;
        self.galaxies = std.ArrayList(Pos).init(allocator);
    }

    pub fn set(self: *Map, y: usize, x: usize, v: u8) void {
        const idx = y * self.cols + x;
        self.buffer.items[idx] = v;
    }

    pub fn print(self: Map) void {
        std.debug.print("\n\nMAP:\n    ", .{});
        // for(0..self.cols) |y| {
        //     std.debug.print("{d: ^3} ", .{ y });
        // }
        std.debug.print("\n", .{});
        for (0..self.rows) |y| {
            // std.debug.print("{d: >3} ", .{ y });
            for (0..self.cols) |x| {
                const idx = y * self.cols + x;
                std.debug.print("{c}", .{self.buffer.items[idx]});
                // std.debug.print("{c: ^3} ", .{ self.buffer.items[idx] });
                // std.debug.print("{d: ^3} ", .{ idx });
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn expandCol(self: *Map, col: usize) void {
        // std.debug.print("\nExpand col {d}", .{col});
        self.cols += EXPANDING_STEPS_PART1;
        self.buffer.resize(self.rows * self.cols) catch {
            std.log.err("\nERROR: could not resize Map buffer", .{});
        };
        for (0..self.rows) |y| {
            const idx = y * self.cols + (col + 1);
            self.buffer.insert(idx, '.') catch unreachable;
        }
        // std.debug.print("\n→ Map size: {d} x {d}", .{ self.cols, self.rows });
    }

    pub fn expandRow(self: *Map, row: usize) void {
        // std.debug.print("\nExpand row {d}", .{row});
        self.rows += EXPANDING_STEPS_PART1;
        self.buffer.resize(self.rows * self.cols) catch unreachable;
        for (0..self.cols) |x| {
            const idx = row * self.cols + x;
            self.buffer.insertAssumeCapacity(idx, '.');
        }
        // std.debug.print("\n→ Map size: {d} x {d}", .{ self.cols, self.rows });
    }

    pub fn expandRowWithoutBuffer(self: *Map, row: usize) void {
        // std.debug.print("\n→ Expand row {d}", .{row});
        for (0..self.galaxies.items.len) |g| {
            const galaxy = &self.galaxies.items[g];
            if(galaxy.y > row) {
                // std.debug.print("\n    → Galaxy {any}", .{ galaxy });
                galaxy.*.y += EXPANDING_STEPS_PART2;
                // std.debug.print(" → \x1B[31m{any}\x1B[0m", .{ galaxy });
            }
        }
        self.rows += EXPANDING_STEPS_PART2;
        // std.debug.print("\n    → Map size: {d} x \x1B[31m{d}\x1B[0m", .{ self.cols, self.rows });
    }

    pub fn expandColWithoutBuffer(self: *Map, col: usize) void {
        // std.debug.print("\n→ Expand col {d}", .{col});
        for (0..self.galaxies.items.len) |g| {
            const galaxy = &self.galaxies.items[g];
            if(galaxy.x > col) {
                // std.debug.print("\n    → Galaxy {any}", .{ galaxy });
                galaxy.*.x += EXPANDING_STEPS_PART2;
                // std.debug.print(" → \x1B[31m{any}\x1B[0m", .{ galaxy });
            }
        }
        self.cols += EXPANDING_STEPS_PART2;
        // std.debug.print("\n    → Map size: \x1B[31m{d}\x1B[0m x {d}", .{ self.cols, self.rows });
    }

    pub fn findGalaxies(self: *Map) *std.ArrayList(Pos) {
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                const idx = y * self.cols + x;
                if (self.buffer.items[idx] == '#') {
                    self.galaxies.append(Pos{ .x = x, .y = y }) catch unreachable;
                }
            }
        }
        // std.debug.print("\nGalaxy count: {d}", .{ self.galaxies.items.len });
        return &self.galaxies;
    }

    pub fn animate(self: *Map) void {
        for(0..self.rows) |dy| {
            for(0..self.cols) |dx| {
                std.debug.print("\x1B[{d};{d}H", .{ dy, dx });
                const idx = dy * self.cols + dx;
                const val = self.buffer.items[idx];
                switch(val) {
                    'X' => std.debug.print("\x1B[33m{c}\x1B[0m", .{ val }),
                    '#' => std.debug.print("\x1B[37m{c}\x1B[0m", .{ val }),
                    '.' => std.debug.print("{c}", .{ ' ' }),
                    else => {},
                }
            }
        }
    }
};

fn manhattenDist(start: Pos, end: Pos) u32 {
    const a = @abs(@as(i32, @intCast(start.x)) - @as(i32, @intCast(end.x)));
    const b = @abs(@as(i32, @intCast(start.y)) - @as(i32, @intCast(end.y)));
    return @intCast(a + b);
}


fn bresenham(start: Pos, end: Pos, map: *Map) u32 {
    _ = map;
    var x0: i32 = @intCast(start.x);
    var y0: i32 = @intCast(start.y);
    const dx: i32 = std.math.absInt(@as(i32, @intCast(end.x)) - @as(i32, @intCast(start.x)))
        catch unreachable;
    const dy: i32 = -(std.math.absInt(@as(i32, @intCast(end.y)) - @as(i32, @intCast(start.y))) catch unreachable);
    const sx: i8 = if(start.x < end.x) 1 else -1;
    const sy: i8 = if(start.y < end.y) 1 else -1;
    var err = dx + dy;
    var e2: i32 = 0;

    var steps: u32 = 0;
    while(true) {
        // if ((x0 != start.x and x0 != end.x) or
        //     (y0 != start.y and y0 != end.y)) {
        //     map.set(@intCast(y0), @intCast(x0), 'X');
        // }

        if (x0 == end.x and y0 == end.y) break;
        e2 = 2 * err;
        if (e2 > dy) {
            err += dy;
            x0 += sx;
            steps += 1;
        }
        if (e2 < dx) {
            err += dx;
            y0 += sy;
            steps += 1;
        }
    }
    return steps;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n\r");

    const col_count: usize = @intCast(row_it.peek().?.len);
    const row_count: usize = @as(usize, @intCast(row_it.buffer.len)) / (col_count + 1);
    std.debug.print("\nMap size: {} x {}", .{ col_count, row_count });

    var map = Map{};
    map.init(allocator, col_count, row_count);

    var y: usize = 0;
    var rows_to_expand = std.ArrayList(usize).init(allocator);
    while (row_it.next()) |row| {
        if (!std.mem.containsAtLeast(u8, row, 1, "#")) {
            rows_to_expand.append(y) catch unreachable;
        }
        for (0..row.len) |x| {
            map.set(y, x, row[x]);
        }
        y += 1;
    }

    var cols_to_expand = std.ArrayList(usize).init(allocator);
    for (0..map.cols) |x| {
        var empty_count: usize = 0;
        for (0..map.rows) |yy| {
            const idx = yy * map.cols + x;
            if (map.buffer.items[idx] == '.')
                empty_count += 1;
        }
        if (empty_count == map.rows) {
            cols_to_expand.append(x) catch unreachable;
        }
    }
    std.debug.print("\n#Column Expansion: {d}", .{ cols_to_expand.items.len });
    std.debug.print("\n#Row Expansion: {d}", .{ rows_to_expand.items.len });

    var expansions: usize = 0;
    for (rows_to_expand.items) |row| {
        map.expandRow(row + expansions);
        expansions += 1;
    }

    expansions = 0;
    for (cols_to_expand.items) |col| {
        // std.debug.print("\nExpand col {d}", .{col});
        map.expandCol(col + expansions);
        expansions += 1;
    }

    const galaxies = map.findGalaxies();

    var pairings: u16 = 0;
    var i: u32 = 0;
    var pairs = std.ArrayList([2]usize).init(allocator);
    for(0..galaxies.items.len) |g_a| {
        for(pairings..galaxies.items.len) |g_b| {
            if (g_a == g_b) continue;
            pairs.append([2]usize{ g_a, g_b }) catch unreachable;
            i += 1;
        }
        pairings += 1;
    }

    var steps: u32 = 0;
    while(pairs.items.len > 0) {
        // const next_idx = rng.random().intRangeLessThan(usize, 0, pairs.items.len);
        const next_idx = 0;
        const next_pair = pairs.swapRemove(next_idx);
        const galaxy_a = galaxies.items[next_pair[0]];
        const galaxy_b = galaxies.items[next_pair[1]];
        // const step_count = bresenham(galaxy_a, galaxy_b, &map);
        const step_count = manhattenDist(galaxy_a, galaxy_b);
        // std.debug.print("\nStep count: {d}", .{ step_count });
        steps += step_count;
        // map.animate();
        // break;
    }

    std.debug.print("\n\nResult: {d}\n", .{ steps });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n\r");

    const col_count: usize = @intCast(row_it.peek().?.len);
    const row_count: usize = @as(usize, @intCast(row_it.buffer.len)) / (col_count + 1);
    std.debug.print("\nMap size: {} x {}", .{ col_count, row_count });

    var map = Map{};
    map.init(allocator, col_count, row_count);

    var y: usize = 0;
    var rows_to_expand = std.ArrayList(usize).init(allocator);
    while (row_it.next()) |row| {
        if (!std.mem.containsAtLeast(u8, row, 1, "#")) {
            rows_to_expand.append(y) catch unreachable;
        }
        for (0..row.len) |x| {
            map.set(y, x, row[x]);
        }
        y += 1;
    }

    var cols_to_expand = std.ArrayList(usize).init(allocator);
    for (0..map.cols) |x| {
        var empty_count: usize = 0;
        for (0..map.rows) |yy| {
            const idx = yy * map.cols + x;
            if (map.buffer.items[idx] == '.')
                empty_count += 1;
        }
        if (empty_count == map.rows) {
            cols_to_expand.append(x) catch unreachable;
        }
    }
    std.debug.print("\n#Column Expansion: {d}", .{ cols_to_expand.items.len });
    std.debug.print("\n#Row Expansion: {d}", .{ rows_to_expand.items.len });

    // Find galaxies before expanding
    const galaxies = map.findGalaxies();

    var expansions: usize = 0;
    for (rows_to_expand.items) |row| {
        map.expandRowWithoutBuffer(row + expansions);
        expansions += EXPANDING_STEPS_PART2;
    }

    expansions = 0;
    for (cols_to_expand.items) |col| {
        map.expandColWithoutBuffer(col + expansions);
        expansions += EXPANDING_STEPS_PART2;
    }

    var pairings: u16 = 0;
    var i: u32 = 0;
    var pairs = std.ArrayList([2]usize).init(allocator);
    for(0..galaxies.items.len) |g_a| {
        for(pairings..galaxies.items.len) |g_b| {
            if (g_a == g_b) continue;
            pairs.append([2]usize{ g_a, g_b }) catch unreachable;
            i += 1;
        }
        pairings += 1;
    }

    var steps: u128 = 0;
    while(pairs.items.len > 0) {
        const next_idx = 0;
        const next_pair = pairs.swapRemove(next_idx);
        const galaxy_a = galaxies.items[next_pair[0]];
        const galaxy_b = galaxies.items[next_pair[1]];
        const step_count = manhattenDist(galaxy_a, galaxy_b);
        // const step_count = bresenham(galaxy_a, galaxy_b, &map);
        steps += step_count;
    }

    std.debug.print("\n\nResult: {d}\n", .{ steps });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try aoc.runPart(allocator, 2023, 11, .PUZZLE, part1);
    try aoc.runPart(allocator, 2023, 11, .PUZZLE, part2);
}
