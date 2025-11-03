const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 15;
const Allocator = std.mem.Allocator;
const log = std.log;

const Dir = enum(u8) {
    U = '^',
    R = '>',
    D = 'v',
    L = '<',

    pub fn vec(self: Dir) @Vector(2, isize) {
        return switch (self) {
            .U => .{ 0, -1 },
            .R => .{ 1, 0 },
            .D => .{ 0, 1 },
            .L => .{ -1, 0 },
        };
    }
};

const ParseResult = struct {
    robot: Robot,
    warehouse: Warehouse,
    movements: std.array_list.Managed(Dir),
};

const Robot = struct {
    pos: @Vector(2, isize),

    pub fn init(self: *Robot, x: usize, y: usize) void {
        self.pos[0] = @intCast(x);
        self.pos[1] = @intCast(y);
    }

    pub fn moveWide(self: *Robot, dir: Dir, warehouse_map: *[][]u8) void {
        const next_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec();
        const warehouse_tile = warehouse_map.*[@intCast(next_pos[1])][@intCast(next_pos[0])];
        switch (warehouse_tile) {
            '.' => self.pos = next_pos,
            '#' => return,
            ']', '[' => {
                if (dir == .R) {
                    var lookahead: isize = 2;
                    var lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                    var next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                    while (true) : (lookahead += 1) {
                        lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                        next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                        if (next_tile == '#') break;
                        if (next_tile == '.') {
                            var b: isize = lookahead_pos[0];
                            while (b >= next_pos[0]) : (b -= 1) {
                                const v: u8 = if (@mod(b - next_pos[0], 2) == 1) '[' else ']';
                                warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(b)] = v;
                            }
                            warehouse_map.*[@intCast(next_pos[1])][@intCast(next_pos[0])] = '.';
                            self.pos = next_pos;
                            break;
                        }
                    }
                }

                if (dir == .L) {
                    var lookahead: isize = 2;
                    var lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                    var next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                    while (true) : (lookahead += 1) {
                        lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                        next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                        if (next_tile == '#') break;
                        if (next_tile == '.') {
                            var b: isize = lookahead_pos[0];
                            while (b <= next_pos[0]) : (b += 1) {
                                const v: u8 = if (@mod(b - next_pos[0], 2) == 1) ']' else '[';
                                warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(b)] = v;
                            }
                            warehouse_map.*[@intCast(next_pos[1])][@intCast(next_pos[0])] = '.';
                            self.pos = next_pos;
                            break;
                        }
                    }
                }

                if (dir == .U or dir == .D) {
                    @panic("Not implemented!");
                }
            },
            else => unreachable,
        }
    }

    pub fn move(self: *Robot, dir: Dir, warehouse_map: *[][]u8) void {
        const next_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec();
        const warehouse_tile = warehouse_map.*[@intCast(next_pos[1])][@intCast(next_pos[0])];
        switch (warehouse_tile) {
            '.' => self.pos = next_pos,
            '#' => return,
            'O' => {
                var lookahead: isize = 2;
                var lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                var next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                while (true) : (lookahead += 1) {
                    lookahead_pos = @as(@Vector(2, isize), @intCast(self.pos)) + dir.vec() * @as(@Vector(2, isize), @splat(lookahead));
                    next_tile = warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])];
                    if (next_tile == '#') break;

                    if (next_tile == '.') {
                        warehouse_map.*[@intCast(lookahead_pos[1])][@intCast(lookahead_pos[0])] = 'O';
                        warehouse_map.*[@intCast(next_pos[1])][@intCast(next_pos[0])] = '.';
                        self.pos = next_pos;
                        break;
                    }
                }
            },
            else => return,
        }
    }
};

const Warehouse = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,

    pub fn init(allocator: Allocator, rows: usize, cols: usize) !Warehouse {
        var instance = Warehouse{};
        instance.rows = rows;
        instance.cols = cols;

        instance.buffer = try allocator.alloc([]u8, instance.cols);
        for (0..instance.cols) |x| {
            instance.buffer[x] = try allocator.alloc(u8, instance.rows);
            for (0..instance.rows) |y| {
                instance.buffer[x][y] = '.';
            }
        }

        return instance;
    }

    pub fn set(self: *Warehouse, pos: @Vector(2, usize), val: u8) void {
        self.buffer[pos[1]][pos[0]] = val;
    }

    pub fn format(self: Warehouse, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.cols) |x| {
            try writer.print("\n", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                try writer.print("{c}", .{val});
            }
        }
        try writer.print("\n ", .{});
    }

    pub fn animate(self: Warehouse, dir: Dir, robot_pos: @Vector(2, isize)) void {
        std.debug.print("{s}", .{t.hide_cursor});
        std.debug.print("\x1B[{d};{d}H", .{ 1, 2 });

        switch (dir) {
            .U => std.debug.print("↑", .{}),
            .R => std.debug.print("→", .{}),
            .D => std.debug.print("↓", .{}),
            .L => std.debug.print("←", .{}),
        }

        for (0..self.cols) |y| {
            for (0..self.rows) |x| {
                std.debug.print("\x1B[{d};{d}H", .{ 2 + y, 2 + x });
                if (x == robot_pos[0] and y == robot_pos[1]) {
                    std.debug.print("{s}@{s} ", .{ t.yellow, t.clear });
                    continue;
                }
                const v = self.buffer[y][x];
                switch (v) {
                    '#' => std.debug.print("{s}{s}{c}{s}", .{ t.bg_red, t.white, v, t.clear }),
                    '.' => std.debug.print("{s}{c}{s}", .{ t.dark_gray, v, t.clear }),
                    else => std.debug.print("{c}", .{v}),
                }
            }
        }
        std.debug.print("\n\n", .{});
        // std.time.sleep(std.time.ns_per_ms * 160);
        // aoc.blockAskForNext();
    }

    pub fn calcGpsCoords(self: *Warehouse) usize {
        var result: usize = 0;
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                if (self.buffer[y][x] == 'O') {
                    result += 100 * y + x;
                }
            }
        }
        return result;
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var split_it = std.mem.splitSequence(u8, trimmed, "\n\n");

    // Robot
    var robot = Robot{ .pos = .{ 0, 0 } };

    // Parse warehouse
    const warehouse_input = split_it.next().?;
    var warehouse_it = std.mem.splitSequence(u8, warehouse_input, "\n");
    const cols: usize = warehouse_it.peek().?.len;
    var rows: usize = 0;
    var y: usize = 0;
    while (warehouse_it.next()) |_| rows += 1;
    warehouse_it.reset();
    var warehouse = try Warehouse.init(allocator, rows, cols);
    while (warehouse_it.next()) |row| : (y += 1) {
        for (0..row.len) |x| {
            const v = row[x];
            if (v == '@') {
                robot.init(x, y);
                warehouse.set(@Vector(2, usize){ x, y }, '.');
                continue;
            }
            warehouse.set(@Vector(2, usize){ x, y }, v);
        }
    }
    log.info("{any}", .{warehouse});

    // Parse movememnts
    const movement_input = std.mem.trim(u8, split_it.next() orelse "", "\n");
    const clean_movement_input = try std.mem.replaceOwned(u8, allocator, movement_input, "\n", "");
    var movements = std.array_list.Managed(Dir).init(allocator);
    for (clean_movement_input) |d| {
        const dir: Dir = @enumFromInt(d);
        try movements.append(dir);
    }
    log.info("{d} movements", .{movements.items.len});

    return ParseResult{
        .robot = robot,
        .warehouse = warehouse,
        .movements = movements,
    };
}

fn parseInputWide(allocator: Allocator, input: []const u8) !ParseResult {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var split_it = std.mem.splitSequence(u8, trimmed, "\n\n");

    // Robot
    var robot = Robot{ .pos = .{ 0, 0 } };

    // Parse warehouse
    const warehouse_input = split_it.next().?;
    var warehouse_it = std.mem.splitSequence(u8, warehouse_input, "\n");
    const cols: usize = warehouse_it.peek().?.len;
    var rows: usize = 0;
    var y: usize = 0;
    while (warehouse_it.next()) |_| rows += 2;
    warehouse_it.reset();
    var warehouse = try Warehouse.init(allocator, rows, cols);
    while (warehouse_it.next()) |row| : (y += 1) {
        for (0..row.len) |x| {
            const v = row[x];
            switch (v) {
                '@' => {
                    robot.init(x * 2, y);
                    warehouse.set(@Vector(2, usize){ x * 2, y }, '.');
                    warehouse.set(@Vector(2, usize){ (x * 2) + 1, y }, '.');
                },
                'O' => {
                    warehouse.set(@Vector(2, usize){ x * 2, y }, '[');
                    warehouse.set(@Vector(2, usize){ (x * 2) + 1, y }, ']');
                },
                '.' => {
                    warehouse.set(@Vector(2, usize){ x * 2, y }, v);
                    warehouse.set(@Vector(2, usize){ (x * 2) + 1, y }, v);
                },
                '#' => {
                    warehouse.set(@Vector(2, usize){ x * 2, y }, v);
                    warehouse.set(@Vector(2, usize){ (x * 2) + 1, y }, v);
                },
                else => unreachable,
            }
        }
    }
    log.info("{any}", .{warehouse});

    // Parse movememnts
    const movement_input = std.mem.trim(u8, split_it.next() orelse "", "\n");
    const clean_movement_input = try std.mem.replaceOwned(u8, allocator, movement_input, "\n", "");
    var movements = std.array_list.Managed(Dir).init(allocator);
    for (clean_movement_input) |d| {
        const dir: Dir = @enumFromInt(d);
        try movements.append(dir);
    }
    log.info("{d} movements", .{movements.items.len});

    return ParseResult{
        .robot = robot,
        .warehouse = warehouse,
        .movements = movements,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var parsed = try parseInput(allocator, input);

    // Movements
    std.debug.print("{s}", .{t.clear_screen});
    for (parsed.movements.items) |d| {
        parsed.robot.move(d, &parsed.warehouse.buffer);
        parsed.warehouse.animate(d, @intCast(parsed.robot.pos));
    }

    // Calculate GPS coordinates
    const result = parsed.warehouse.calcGpsCoords();
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var parsed = try parseInputWide(allocator, input);
    log.info("{any}", .{parsed.warehouse});

    // Movements
    std.debug.print("{s}", .{t.clear_screen});
    parsed.warehouse.animate(Dir.D, @intCast(parsed.robot.pos));
    aoc.blockAskForNext();
    for (parsed.movements.items) |d| {
        parsed.robot.moveWide(d, &parsed.warehouse.buffer);
        parsed.warehouse.animate(d, @intCast(parsed.robot.pos));
        aoc.blockAskForNext();
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
