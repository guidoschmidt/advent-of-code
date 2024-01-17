const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Map = struct {
    cols: usize = undefined,
    rows: usize = undefined,
    buffer: std.ArrayList(u8) = undefined,

    pub fn init(self: *Map, cols: usize, rows: usize) void {
        self.cols = cols;
        self.rows = rows;
        self.buffer = std.ArrayList(u8).init(allocator);
        self.buffer.items = allocator.alloc(u8, self.cols * self.rows) catch unreachable;
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
        for(0..self.rows) |y| {
            // std.debug.print("{d: >3} ", .{ y });
            for(0..self.cols) |x| {
                const idx = y * self.cols + x;
                std.debug.print("{c}", .{ self.buffer.items[idx] });
                // std.debug.print("{c: ^3} ", .{ self.buffer.items[idx] });
                // std.debug.print("{d: ^3} ", .{ idx });
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn expandCol(self: *Map, col: usize) void {
        std.debug.print("\nExpand col {d}", .{ col });
        self.cols += 1;
        self.buffer.resize(self.rows * self.cols) catch {
            std.log.err("\nERROR: could not resize Map buffer", .{});
        };
        for (0..self.rows) |y| {
            const idx = y * self.cols + (col + 1);
            self.buffer.insert(idx, '.') catch unreachable;
        }
        std.debug.print("\n→ Map size: {d} x {d}", .{ self.cols, self.rows });
    }

    pub fn expandRow(self: *Map, row: usize) void {
        std.debug.print("\nExpand row {d}", .{ row });
        self.rows += 1;
        self.buffer.resize(self.rows * self.cols) catch unreachable;
        for (0..self.cols) |x| {
            const idx = row * self.cols + x;
            self.buffer.insertAssumeCapacity(idx, '.');
        }
        std.debug.print("\n→ Map size: {d} x {d}", .{ self.cols, self.rows });
    }
};


fn part1(input: []const u8) void {
    var row_it = std.mem.tokenize(u8, input, "\n\r");

    const col_count: usize = @intCast(row_it.peek().?.len);
    const row_count: usize = @as(usize, @intCast(row_it.buffer.len)) / (col_count + 1);
    std.debug.print("\nMap size: {} x {}", .{ col_count, row_count });

    var map = Map{};
    map.init(col_count, row_count);

    var y: usize = 0;
    var rows_to_expand = std.ArrayList(usize).init(allocator);
    while(row_it.next()) |row| {
        if (!std.mem.containsAtLeast(u8, row, 1, "#")) {
            rows_to_expand.append(y) catch unreachable;
        }
        for (0..row.len) |x| {
            map.set(y, x, row[x]);
        }
        y += 1;
    }
    map.print();

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

    var expansions: usize = 0;
    for (rows_to_expand.items) |row| {
        map.expandRow(row + expansions);
        expansions += 1;
    }

    expansions = 0;
    for (cols_to_expand.items) |col| {
        std.debug.print("\nExpand col {d}", .{ col });
        map.expandCol(col + expansions);
        expansions += 1;
    }

    map.print();
}

fn part2(input: []const u8) void {
    _ = input;
    
}

pub fn main() !void {
    try common.runDay(allocator, 11, .PUZZLE, part1, part2);
}
