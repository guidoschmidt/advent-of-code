const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 14;
const Allocator = std.mem.Allocator;
const log = std.log;

const Robot = struct {
    pos: @Vector(2, isize),
    vel: @Vector(2, isize),

    pub fn format(self: Robot, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("P {d: >5}, V {d: >5}", .{ self.pos, self.vel });
    }

    pub fn move(self: *Robot, time: usize, rows: usize, cols: usize) void {
        const bounds = @Vector(2, isize){ @intCast(rows), @intCast(cols) };
        self.pos = @mod(self.pos + (self.vel * @as(@TypeOf(self.vel), @splat(@intCast(time)))), bounds);
    }
};

const Bathroom = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]usize = undefined,

    pub fn init(allocator: Allocator, rows: usize, cols: usize) !Bathroom {
        var bathroom = Bathroom{};
        bathroom.rows = rows;
        bathroom.cols = cols;

        bathroom.buffer = try allocator.alloc([]usize, bathroom.cols);

        for (0..bathroom.cols) |x| {
            bathroom.buffer[x] = try allocator.alloc(usize, bathroom.rows);
            for (0..bathroom.rows) |y| {
                bathroom.buffer[x][y] = 0;
            }
        }

        return bathroom;
    }

    pub fn format(self: Bathroom, writer: *std.Io.Writer) !void {
        for (0..self.cols) |x| {
            try writer.print("\n", .{});
            for (0..self.rows) |y| {
                const val = self.buffer[x][y];
                switch (val) {
                    0 => try writer.print(" ", .{}),
                    else => try writer.print("{d}", .{val}),
                }
            }
        }
        try writer.print("\n ", .{});
    }

    pub fn animate(self: *Bathroom, robots: *std.array_list.Managed(Robot), t: usize) void {
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                self.buffer[x][y] = 0;
            }
        }
        for (robots.items) |*r| {
            r.move(t, self.rows, self.cols);
            self.increase(r.pos, 1);
        }

        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                std.debug.print("\x1B[{d};{d}H", .{ y, x });
                const v = self.buffer[x][y];
                switch (v) {
                    0 => std.debug.print(" ", .{}),
                    else => std.debug.print("{d}", .{v}),
                }
            }
            // log.info("{any}", .{self});
        }
        log.info("\n{d: >20}", .{t});
        // std.time.sleep(std.time.ns_per_ms * 16);
    }

    pub fn increase(self: *Bathroom, pos: @Vector(2, isize), val: usize) void {
        self.buffer[@intCast(pos[1])][@intCast(pos[0])] += val;
    }

    pub fn set(self: *Bathroom, pos: @Vector(2, isize), val: usize) void {
        self.buffer[@intCast(pos[1])][@intCast(pos[0])] = val;
    }

    pub fn countInSector(self: *Bathroom, xStart: usize, yStart: usize) usize {
        var result: usize = 0;

        for (xStart..@min((xStart + self.cols / 2), self.cols)) |x| {
            for (yStart..@min(yStart + self.rows / 2, self.rows)) |y| {
                // log.info("{d},{d}", .{ x, y });
                result += self.buffer[x][y];
            }
        }

        return result;
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.array_list.Managed(Robot) {
    const trimmed = std.mem.trimRight(u8, input, "\n");

    var robots = std.array_list.Managed(Robot).init(allocator);

    var row_it = std.mem.splitSequence(u8, trimmed, "\n");
    while (row_it.next()) |row| {
        var pv_it = std.mem.splitSequence(u8, row, " ");
        const pos_str = pv_it.next().?[2..];
        var pos_it = std.mem.splitSequence(u8, pos_str, ",");
        const px = try std.fmt.parseInt(isize, pos_it.next().?, 10);
        const py = try std.fmt.parseInt(isize, pos_it.next().?, 10);
        const pos = @Vector(2, isize){ px, py };

        const vel_str = pv_it.next().?[2..];
        var vel_it = std.mem.splitSequence(u8, vel_str, ",");
        const vx = try std.fmt.parseInt(isize, vel_it.next().?, 10);
        const vy = try std.fmt.parseInt(isize, vel_it.next().?, 10);
        const vel = @Vector(2, isize){ vx, vy };

        try robots.append(Robot{
            .pos = pos,
            .vel = vel,
        });
    }
    return robots;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const rows = 101;
    const cols = 103;

    var bathroom = try Bathroom.init(allocator, rows, cols);
    const robots = try parseInput(allocator, input);

    for (robots.items) |r| log.info("{any}", .{r});

    for (robots.items) |*r| {
        r.move(100, bathroom.rows, bathroom.cols);
        bathroom.increase(r.pos, 1);
    }

    log.info("{f}", .{bathroom});

    const quadrants = [4]@Vector(2, usize){ .{ 0, 0 }, .{ bathroom.cols / 2 + 1, 0 }, .{ 0, bathroom.rows / 2 + 1 }, .{ bathroom.cols / 2 + 1, bathroom.rows / 2 + 1 } };

    var result: usize = 1;
    for (0..quadrants.len) |i| {
        const q = quadrants[i];
        const res = bathroom.countInSector(q[0], q[1]);
        result *= res;
    }

    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const rows = 101;
    const cols = 103;

    var bathroom = try Bathroom.init(allocator, rows, cols);
    const robots = try parseInput(allocator, input);

    const solution = 8159;
    for (robots.items) |*r| {
        r.move(solution, bathroom.rows, bathroom.cols);
        bathroom.increase(r.pos, 1);
    }
    log.info("{f}", .{bathroom});

    // Finding the solution:
    // Increase the robots position by 1 step and let it run, until
    // a row contains a lot of consecutive 1s:

    // var t: usize = 0;
    // while (true) : (t += 1) {
    //     for (0..bathroom.cols) |x| {
    //         for (0..bathroom.rows) |y| {
    //             bathroom.buffer[x][y] = 0;
    //         }
    //     }
    //     for (robots.items) |*r| {
    //         r.move(1, bathroom.rows, bathroom.cols);
    //         bathroom.increase(r.pos, 1);
    //     }

    //     log.info("{any}", .{bathroom});
    //     log.info("{d}", .{t});
    //     for (0..bathroom.buffer.len) |y| {
    //         if (std.mem.containsAtLeast(usize, bathroom.buffer[y], 1, &[_]usize{
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //             1,
    //         })) {
    //             aoc.blockAskForNext();
    //         }
    //     }
    // }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
