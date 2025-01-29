const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log;

const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 18;
const Cell = struct {
    visited: bool = false,
    pos: @Vector(2, usize) = .{ 0, 0 },
    previous: @Vector(2, usize) = .{ 0, 0 },
    g: usize,
    h: usize,

    pub fn f(self: Cell) usize {
        return self.g + self.h;
    }
};

const MemorySpace = struct {
    size: @Vector(2, usize) = undefined,
    buffer: [][]u8 = undefined,
    corruptions: std.ArrayList(@Vector(2, usize)) = undefined,
    corruption_idx: usize = 1024,
    cell_buffer: [][]Cell = undefined,
    current_cell: ?Cell = undefined,

    pub fn init(allocator: Allocator, size: @Vector(2, usize)) !MemorySpace {
        var instance = MemorySpace{};
        instance.size = size;

        instance.buffer = try allocator.alloc([]u8, instance.size[0]);
        instance.corruptions = std.ArrayList(@Vector(2, usize)).init(allocator);

        for (0..instance.size[0]) |x| {
            instance.buffer[x] = try allocator.alloc(u8, instance.size[1]);
            for (0..instance.size[1]) |y| {
                instance.buffer[x][y] = '.';
            }
        }

        return instance;
    }

    pub fn reset(self: *MemorySpace) void {
        for (0..self.size[0]) |x| {
            for (0..self.size[1]) |y| {
                self.buffer[x][y] = '.';
            }
        }
    }

    pub fn markCorruptions(self: *MemorySpace, end: usize) void {
        for (0..self.corruptions.items.len) |i| {
            if (i >= end) break;
            self.setCorrupt(self.corruptions.items[i]);
        }
    }

    pub fn setCorrupt(self: *MemorySpace, pos: @Vector(2, usize)) void {
        self.buffer[pos[1]][pos[0]] = '#';
    }

    pub fn testCorruptions(self: *MemorySpace, start: usize) ?@Vector(2, usize) {
        for (start..self.corruptions.items.len) |i| {
            const pos = self.corruptions.items[i];
            if (self.buffer[pos[1]][pos[0]] == 'O') return pos;
        }
        return null;
    }

    pub fn aStar(self: *MemorySpace, allocator: Allocator, trace_path: bool) !?usize {
        const result: ?usize = undefined;

        self.cell_buffer = try allocator.alloc([]Cell, self.size[1]);
        for (0..self.size[1]) |y| {
            self.cell_buffer[y] = try allocator.alloc(Cell, self.size[0]);
            for (0..self.size[0]) |x| {
                self.cell_buffer[y][x] = Cell{
                    .pos = .{ x, y },
                    .previous = .{ 0, 0 },
                    .g = undefined,
                    .h = std.math.sqrt(x * x + y * y),
                };
            }
        }

        var cell_list = std.ArrayList(Cell).init(allocator);
        try cell_list.append(self.cell_buffer[0][0]);

        while (cell_list.items.len > 0) {
            std.mem.sort(Cell, cell_list.items, {}, comptime struct {
                pub fn f(_: void, a: Cell, b: Cell) bool {
                    return a.f() > b.f();
                }
            }.f);

            var current_cell = cell_list.pop();
            self.current_cell = current_cell;
            self.buffer[current_cell.pos[1]][current_cell.pos[0]] = 'X';

            if (current_cell.pos[0] == self.size[0] - 1 and
                current_cell.pos[1] == self.size[1] - 1)
            {
                if (trace_path)
                    return self.tracePath(&current_cell);
                return current_cell.g;
            }

            const neighbours = [4]@Vector(2, usize){
                .{ current_cell.pos[0] -| 1, current_cell.pos[1] },
                .{ current_cell.pos[0], current_cell.pos[1] -| 1 },
                .{ @min(current_cell.pos[0] + 1, self.size[0] - 1), current_cell.pos[1] },
                .{ current_cell.pos[0], @min(current_cell.pos[1] + 1, self.size[1] - 1) },
            };
            for (neighbours) |n| {
                const tentative_g = current_cell.g + 1;
                var neighbour_cell = self.cell_buffer[n[1]][n[0]];
                if (neighbour_cell.visited) continue;

                if (tentative_g < neighbour_cell.g or !neighbour_cell.visited) {
                    neighbour_cell.g = tentative_g;
                    neighbour_cell.previous = current_cell.pos;
                    neighbour_cell.visited = true;
                }
                self.cell_buffer[n[1]][n[0]] = neighbour_cell;

                if (self.buffer[n[1]][n[0]] == '.') {
                    try cell_list.append(neighbour_cell);
                }
            }

            self.animate();
        }

        return result;
    }

    fn tracePath(self: *MemorySpace, current_cell: *Cell) usize {
        var count: usize = 0;
        while (true) {
            const p = current_cell.pos;
            const prev = current_cell.previous;
            self.buffer[p[1]][p[0]] = 'O';

            self.animate();

            if (p[0] == 0 and p[1] == 0) {
                log.info("{d}", .{count});
                break;
            }

            current_cell.* = self.cell_buffer[prev[1]][prev[0]];
            count += 1;
        }
        return count;
    }

    pub fn animate(self: MemorySpace) void {
        std.debug.print(t.clear_screen, .{});
        std.debug.print(t.hide_cursor, .{});
        std.debug.print(t.yx, .{ 1, 1 });
        std.debug.print("Corruption Index: {d}", .{self.corruption_idx});
        for (0..self.size[0]) |x| {
            for (0..self.size[1]) |y| {
                std.debug.print(t.yx, .{ 2 + y, 2 + x * 2 });
                const val = self.buffer[y][x];
                switch (val) {
                    'O' => std.debug.print("{s}{c} {s}", .{ t.bg_green, ' ', t.clear }),
                    '#' => std.debug.print("{s}{c} {s}", .{ t.bg_red, ' ', t.clear }),
                    'X' => std.debug.print("{s}{c} {s}", .{ t.bg_white, ' ', t.clear }),
                    else => std.debug.print("{s}{c} {s}", .{ t.dark_gray, val, t.clear }),
                }
            }
        }
    }

    pub fn format(self: MemorySpace, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.size[0]) |x| {
            try writer.print("\n", .{});
            for (0..self.size[1]) |y| {
                const val = self.buffer[x][y];
                switch (val) {
                    'O' => try writer.print("{s}{c} {s}", .{ t.bg_yellow, ' ', t.clear }),
                    '#' => try writer.print("{s}{c} {s}", .{ t.bg_red, ' ', t.clear }),
                    else => try writer.print("{c} ", .{val}),
                }
                try writer.print("{s}", .{t.clear});
            }
        }
        try writer.print("\n\n ", .{});
        for (0..self.size[0]) |x| {
            try writer.print("\n", .{});
            for (0..self.size[1]) |y| {
                const val = self.buffer[x][y];
                if (val == '#') {
                    try writer.print("{s}{c: ^4}{s}", .{ t.bg_red, '#', t.clear });
                    continue;
                }
                const path_val = self.cell_buffer[x][y].h;
                try writer.print("{d: >4}", .{path_val});
            }
        }
        try writer.print("\n\n ", .{});
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !MemorySpace {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var split_it = std.mem.splitSequence(u8, trimmed, "\n");

    const size = @Vector(2, usize){ 71, 71 };
    var memory_space = try MemorySpace.init(allocator, size);

    var idx: usize = 0;
    while (split_it.next()) |row| : (idx += 1) {
        var num_it = std.mem.splitSequence(u8, row, ",");
        const x = try std.fmt.parseInt(usize, num_it.next().?, 10);
        const y = try std.fmt.parseInt(usize, num_it.next().?, 10);
        try memory_space.corruptions.append(.{ x, y });
    }
    log.info("{d}", .{idx});

    return memory_space;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var memory_space = try parseInput(allocator, input);
    memory_space.markCorruptions(memory_space.corruption_idx);

    std.debug.print(t.hide_cursor, .{});
    std.debug.print(t.clear_screen, .{});
    const result = try memory_space.aStar(allocator, true);
    std.debug.print("\nResult: {any}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var memory_space = try parseInput(allocator, input);

    log.info("# Total Corruptions: {d}", .{memory_space.corruptions.items.len});

    var idx: usize = 2900;
    var blocking_pos = memory_space.corruptions.items[idx];
    const step: isize = -1;
    while (true) : (idx = @intCast(@as(isize, @intCast(idx)) + step)) {
        memory_space.reset();
        memory_space.corruption_idx = idx;
        memory_space.markCorruptions(idx);

        const result = try memory_space.aStar(allocator, false);

        log.info("Curruption Index: {d}", .{idx});

        if (result) |r| {
            // Found a proper solution, check next index
            std.debug.print("\nResult: {d}", .{r});
        } else {
            // Found no solution, there's a blocking corrupted memory block!
            blocking_pos = memory_space.corruptions.items[idx];
            std.debug.print("\nResult: {d}, {d}", .{ blocking_pos, memory_space.current_cell.?.pos });
            // aoc.blockAskForNext();
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
