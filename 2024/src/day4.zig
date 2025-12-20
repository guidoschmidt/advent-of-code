const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 4; // @TODO
const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    map: Map,
    candidates: std.array_list.Managed(@Vector(2, isize)),
};

const Map = struct {
    rows: usize,
    cols: usize,
    buffer: [][]u8,
    result: [][]u8,

    pub fn format(self: Map, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                try writer.print("{c}", .{self.buffer[x][y]});
            }
        }
        try writer.print("\n\n ", .{});
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                try writer.print("{c}", .{self.result[x][y]});
            }
        }
    }

    fn get(self: Map, pos: @Vector(2, isize)) u8 {
        return self.buffer[@intCast(pos[1])][@intCast(pos[0])];
    }

    fn set(self: Map, pos: @Vector(2, isize), v: u8) void {
        self.result[@intCast(pos[1])][@intCast(pos[0])] = v;
    }
};

fn parseInput(allocator: Allocator, input: []const u8, start: u8) !ParseResult {
    const cleaned_input = std.mem.trimRight(u8, input, "\n");
    var row_it = std.mem.splitSequence(u8, cleaned_input, "\n");

    var row_count: usize = 0;
    const col_count: usize = row_it.peek().?.len;
    row_count = row_it.buffer.len / col_count;
    log.info("Map size {d} x {d}", .{ row_count, col_count });

    var candidates = std.array_list.Managed(@Vector(2, isize)).init(allocator);
    var map = Map{
        .rows = row_count,
        .cols = col_count,
        .buffer = try allocator.alloc([]u8, col_count),
        .result = try allocator.alloc([]u8, col_count),
    };

    var x: usize = 0;
    while (row_it.next()) |row| : (x += 1) {
        map.buffer[x] = try allocator.alloc(u8, row_count);
        map.result[x] = try allocator.alloc(u8, row_count);
        for (0..row_count) |y| {
            if (row[y] == start) {
                try candidates.append(.{ @intCast(y), @intCast(x) });
            }
            map.buffer[x][y] = row[y];
            map.result[x][y] = '.';
        }
        log.info("{s}", .{row});
    }

    return ParseResult{
        .map = map,
        .candidates = candidates,
    };
}

fn checkDir(comptime search: []const u8, map: *Map, pos: @Vector(2, isize), dir: @Vector(2, isize)) bool {
    var word = [_]u8{'_'} ** search.len;
    for (0..search.len) |i| {
        const at = pos + @as(@TypeOf(pos), @splat(@intCast(i))) * dir;
        if (at[0] >= map.cols or at[1] >= map.rows or
            at[0] < 0 or at[1] < 0) return false;
        word[i] = map.get(at);
    }
    if (std.mem.eql(u8, &word, search)) {
        for (0..search.len) |i| {
            const at = pos + @as(@TypeOf(pos), @splat(@intCast(i))) * dir;
            if (word[i] == search[i]) {
                map.set(at, search[i]);
            }
        }
        return true;
    }
    return false;
}

fn checkDiag(map: *Map, pos: @Vector(2, isize)) bool {
    const search = "MAS".*;
    var search_reversed: @TypeOf(search) = undefined;
    for (0..search.len) |i| {
        search_reversed[i] = search[search.len - 1 - i];
    }

    var word_a = [_]u8{'_'} ** search.len;
    var word_b = [_]u8{'_'} ** search.len;
    word_a[1] = 'A';
    word_b[1] = 'A';

    // Diagonal top right -- bottom left
    var diag = pos + @Vector(2, isize){ -1, 1 };
    if (diag[0] < 0 or diag[1] < 0 or
        diag[0] >= map.cols or diag[1] >= map.rows) return false;
    word_a[0] = map.get(diag);

    diag = pos + @Vector(2, isize){ 1, -1 };
    if (diag[0] < 0 or diag[1] < 0 or
        diag[0] >= map.cols or diag[1] >= map.rows) return false;
    word_a[2] = map.get(diag);

    // Diagonal top left -- bottom right
    diag = pos + @Vector(2, isize){ 1, 1 };
    if (diag[0] < 0 or diag[1] < 0 or
        diag[0] >= map.cols or diag[1] >= map.rows) return false;
    word_b[0] = map.get(diag);

    diag = pos + @Vector(2, isize){ -1, -1 };
    if (diag[0] < 0 or diag[1] < 0 or
        diag[0] >= map.cols or diag[1] >= map.rows) return false;
    word_b[2] = map.get(diag);

    var is_x = false;
    if ((std.mem.eql(u8, &word_a, &search) or
        std.mem.eql(u8, &word_a, &search_reversed)) and
        (std.mem.eql(u8, &word_b, &search) or
            std.mem.eql(u8, &word_b, &search_reversed)))
    {
        for ([_]@Vector(2, isize){ .{ 0, 0 }, .{ -1, 1 }, .{ 1, -1 }, .{ 1, 1 }, .{ -1, -1 } }) |offset| {
            map.set(pos + offset, map.get(pos + offset));
        }
        is_x = true;
    }

    return is_x;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input, 'X');

    var map = parsed.map;
    var candidates = parsed.candidates;

    var xmas_count: usize = 0;

    while (candidates.items.len > 0) {
        const next = candidates.pop();

        if (map.get(next) == 'X') {
            map.set(next, 'X');
        }

        const search = "XMAS";
        xmas_count += if (checkDir(search, &map, next, .{ 1, 0 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ -1, 0 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ 0, 1 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ 0, -1 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ 1, 1 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ -1, 1 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ -1, -1 })) 1 else 0;
        xmas_count += if (checkDir(search, &map, next, .{ 1, -1 })) 1 else 0;
    }

    log.info("{any}", .{map});
    std.debug.print("\nResult: {d}", .{xmas_count});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input, 'A');

    var map = parsed.map;
    var candidates = parsed.candidates;

    var mas_count: usize = 0;

    while (candidates.items.len > 0) {
        const next = candidates.pop().?;
        mas_count += if (checkDiag(&map, next)) 1 else 0;
    }

    log.info("{any}", .{map});
    std.debug.print("\nResult: {d}", .{mas_count});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
