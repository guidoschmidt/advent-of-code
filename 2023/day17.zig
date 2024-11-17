const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const Allocator = std.mem.Allocator;

const Cell = struct {
    pos: @Vector(2, usize) = .{ 0, 0 },
    previous: @Vector(2, usize) = .{ 0, 0 },

    cost: i32 = -1,
};

const Map = struct {
    width: usize,
    height: usize,
    buffer: [][]u8 = undefined,
    cells: [][]Cell = undefined,
    viz_buffer: [][]u8 = undefined,
    heat_loss: i32 = 0,

    start: @Vector(2, usize),
    destination: @Vector(2, usize),

    pub fn init(self: *Map, allocator: Allocator, input: *const []u8) !void {
        self.buffer = try allocator.alloc([]u8, self.height);
        self.viz_buffer = try allocator.alloc([]u8, self.height);
        for (0..self.height) |y| {
            self.buffer[y] = try allocator.alloc(u8, self.width);
            self.viz_buffer[y] = try allocator.alloc(u8, self.width);
            for (0..self.width) |x| {
                self.viz_buffer[y][x] = 'C';
                const val = input.*[y * self.width + x];
                const digit = try std.fmt.charToDigit(val, 10);
                self.buffer[y][x] = digit;
            }
        }
    }

    fn printBuffer(self: *Map, comptime T: type, buffer: [][]T) void {
        std.debug.print("\n\n", .{});
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const val = buffer[y][x];
                switch (T) {
                    bool => {
                        switch (val) {
                            true => std.debug.print("{s}{s}{s}", .{ t.green, "●", t.clear }),
                            false => std.debug.print("{s}{s}{s}", .{ t.red, "●", t.clear }),
                        }
                    },
                    u8 => {
                        switch (val) {
                            '<', '>', 'v', '^' => std.debug.print("{s}{c}{s}", .{ t.red, val, t.clear }),
                            '.', 'X', 'L', 'F', 'R' => std.debug.print("{s}{c}{s}", .{ t.green, val, t.clear }),
                            'S', 'D' => std.debug.print("{s}{c}{s}", .{ t.yellow, val, t.clear }),
                            '_', 'C' => std.debug.print("{c}", .{val}),
                            else => std.debug.print("{d}", .{val}),
                        }
                    },
                    else => {},
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn tracePath(self: *Map, x_start: usize, y_start: usize) void {
        var x = x_start;
        var y = y_start;
        var prev = self.cells[y][x].previous;
        self.heat_loss += self.buffer[y][x];
        self.setViz(x, y, 'D');
        while (true) {
            x = prev[0];
            y = prev[1];
            self.setViz(x, y, 'D');
            prev = self.cells[y][x].previous;
            self.heat_loss += self.buffer[y][x];
            if (x == self.start[0] and y == self.start[1]) break;
        }
        self.vizualise();
    }

    pub fn aStar(self: *Map, allocator: Allocator) !void {
        var closedList = try allocator.alloc([]bool, self.height);
        self.cells = try allocator.alloc([]Cell, self.height);
        for (0..self.height) |x| {
            closedList[x] = try allocator.alloc(bool, self.width);
            self.cells[x] = try allocator.alloc(Cell, self.width);
            for (0..self.width) |y| {
                closedList[x][y] = false;
                self.cells[x][y] = Cell{
                    .pos = .{ @intCast(x), @intCast(y) },
                    .previous = .{ 0, 0 },
                    .cost = -1,
                };
            }
        }

        // Start cell
        self.cells[self.start[0]][self.start[1]].cost = 0;
        self.cells[self.start[0]][self.start[1]].previous = @intCast(self.start);

        var openList = std.ArrayList(@Vector(2, usize)).init(allocator);

        try openList.append(self.start);

        pathsearch: while (openList.items.len > 0) {
            std.mem.sort(@Vector(2, usize), openList.items, self, comptime struct {
                pub fn f(ctx: *Map, a: @Vector(2, usize), b: @Vector(2, usize)) bool {
                    return ctx.cells[a[1]][a[0]].cost > ctx.cells[b[1]][b[0]].cost;
                }
            }.f);

            const next = openList.pop();

            const x = next[0];
            const y = next[1];
            closedList[y][x] = true;
            std.debug.print("\nPOS: [{d} x {d}] → {d}", .{ x, y, self.cells[y][x].cost });

            const neighbors = [4]@Vector(2, isize){
                .{ -1, 0 },
                .{ 1, 0 },
                .{ 0, -1 },
                .{ 0, 1 },
            };
            for (neighbors) |neighbor| {
                const test_x: isize = @as(isize, @intCast(x)) + neighbor[0];
                const test_y: isize = @as(isize, @intCast(y)) + neighbor[1];

                if (self.valid(test_x, test_y)) {
                    const next_x: usize = @intCast(test_x);
                    const next_y: usize = @intCast(test_y);

                    self.tracePath(next_x, next_y);

                    if (closedList[next_y][next_x]) continue;

                    if (self.isDestination(next_x, next_y)) {
                        self.cells[next_y][next_x].previous = .{ x, y };
                        std.debug.print("\n{s}Destination cell found!{s}", .{ t.red, t.clear });
                        break :pathsearch;
                    }

                    const cost_new = self.cells[y][x].cost + self.buffer[@intCast(next_y)][@intCast(next_x)];

                    if (self.cells[next_y][next_x].cost == -1 or
                        self.cells[next_y][next_x].cost < cost_new)
                    {
                        self.cells[next_y][next_x].cost = cost_new;
                        self.cells[next_y][next_x].previous = .{ x, y };
                        try openList.append(.{ next_x, next_y });
                    }
                }
            }
            self.printBuffer(bool, closedList);

            aoc.blockAskForNext();
        }
    }

    pub fn printCells(self: *Map, cells: *const [][]Cell) void {
        std.debug.print("\n\n", .{});
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const val = cells.*[y][x].cost;
                switch (val) {
                    else => std.debug.print("{d: >10} | ", .{val}),
                }
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn vizualise(self: *Map) void {
        self.printBuffer(u8, self.viz_buffer);
    }

    pub fn print(self: *Map) void {
        self.printBuffer(u8, self.buffer);
    }

    pub fn get(self: *Map, x: usize, y: usize) u8 {
        return self.buffer[y][x];
    }

    pub fn set(self: *Map, x: usize, y: usize, val: u8) void {
        self.buffer[y][x] = val;
    }

    pub fn setViz(self: *Map, x: usize, y: usize, val: u8) void {
        self.viz_buffer[y][x] = val;
    }

    pub fn valid(self: *Map, x: isize, y: isize) bool {
        const v = x >= 0 and y >= 0 and x < self.width and y < self.height;
        std.debug.print("\nIs valid? [{d} x {d}] -> {any}", .{ x, y, v });
        return v;
    }

    fn isDestination(self: *Map, x: usize, y: usize) bool {
        return self.destination[0] == x and self.destination[1] == y;
    }

    pub fn calcHeuristic(self: *Map, x: usize, y: usize) i32 {
        return @intCast(@abs(x -| self.destination[0]) + @abs(y -| self.destination[1]));
    }
};

const Path = struct {
    pos: @Vector(2, isize) = .{ 1, 0 },
    last: @Vector(2, isize) = .{ 0, 0 },
    heat_loss: usize = 0,
    step_counter: usize = 0,
};

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const cleaned_input = try std.mem.replaceOwned(u8, allocator, input, "\n", "");
    var row_it = std.mem.tokenize(u8, input, "\n");

    const width = row_it.peek().?.len;
    var height: usize = 0;
    while (row_it.next()) |_| height += 1;

    std.debug.print("\nMap size {d} x {d}", .{ width, height });
    var map = Map{ .width = width, .height = height, .start = .{ 0, 0 }, .destination = .{ width - 1, height - 1 } };
    try map.init(allocator, &cleaned_input);
    map.setViz(map.start[0], map.start[1], 'S');
    map.setViz(map.destination[0], map.destination[1], 'D');

    map.print();
    map.vizualise();

    try map.aStar(allocator);

    std.debug.print("\nResult: {d}", .{map.heat_loss});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try aoc.runPart(gpa, 2023, 17, .EXAMPLE, part1);
    try aoc.runPart(gpa, 2023, 17, .EXAMPLE, part2);
}
