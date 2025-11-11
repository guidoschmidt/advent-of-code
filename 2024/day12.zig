const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");
const VectorSet = @import("datastructures").VectorSet;

const DAY: u8 = 12;
const Allocator = std.mem.Allocator;
const log = std.log;
const rng_gen = std.Random.DefaultPrng;
var rng: std.Random.Xoshiro256 = rng_gen.init(0);

const Dir = enum(u3) {
    N,
    E,
    S,
    W,

    pub fn turn(self: Dir) Dir {
        var v = @intFromEnum(self);
        v += 1;
        v = @mod(v, 4);
        return @enumFromInt(v);
    }

    pub fn toVec(self: Dir) @Vector(2, isize) {
        return switch (self) {
            .N => @Vector(2, isize){ 0, -1 },
            .E => @Vector(2, isize){ 1, 0 },
            .S => @Vector(2, isize){ 0, 1 },
            .W => @Vector(2, isize){ -1, 0 },
        };
    }

    pub fn fromVec(v: @Vector(2, isize)) Dir {
        if (v[0] == 0 and v[1] == 1) return Dir.N;
        if (v[0] == 1 and v[1] == 0) return Dir.E;
        if (v[0] == 0 and v[1] == -1) return Dir.S;
        if (v[0] == -1 and v[1] == 0) return Dir.W;
        return Dir.E;
    }
};

const Region = struct {
    label: u8 = undefined,
    tiles: VectorSet(2, usize),
    color: usize = 20,

    area: usize = 0,
    perimeter: usize = 0,
    sides: usize = 0,

    pub fn init(allocator: Allocator, label: u8) !Region {
        const region = Region{
            .tiles = VectorSet(2, usize).init(allocator),
            .color = rng.random().intRangeAtMost(usize, 20, 120),
            .label = label,
        };
        return region;
    }

    pub fn isNeighbour(self: *Region, v: @Vector(2, usize)) bool {
        var is_neighbour: bool = false;
        var tit = self.tiles.iterator();
        while (tit.next()) |tile| {
            const diff = @as(@Vector(2, isize), @intCast(tile.*)) - @as(@Vector(2, isize), @intCast(v));
            if (@abs(diff[0]) <= 1 and @abs(diff[1]) <= 1) {
                is_neighbour = true;
                break;
            }
        }
        return is_neighbour;
    }

    pub fn animate(self: *Region, offset: @Vector(2, usize)) void {
        var tit = self.tiles.iterator();
        while (tit.next()) |xy| {
            std.debug.print(t.yx, .{ offset[1] + xy[1], offset[0] + xy[0] * 2 });
            std.debug.print(t.bg_color, .{self.color});
            std.debug.print("{c} {s}", .{ self.label, t.clear });
        }
    }

    pub fn calculatePriceWithPerimeter(self: *Region) !usize {
        return self.area * self.perimeter;
    }

    pub fn calculatePriceWithSides(self: *Region) !usize {
        return self.area * self.sides;
    }

    pub fn format(self: Region, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\nREGION {c} [{d}]", .{ self.label, self.tiles.count() });
        try writer.print("\n    Area {d}", .{self.area});
        try writer.print("\n    Perimeter {d}", .{self.perimeter});
        try writer.print("\n    Sides {d}", .{self.sides});
        var tit = self.tiles.iterator();
        while (tit.next()) |tile| {
            try writer.print("\n{d}", .{tile.*});
        }
    }
};

const GardenMap = struct {
    rows: usize = undefined,
    cols: usize = undefined,
    buffer: [][]u8 = undefined,
    processed: [][]bool = undefined,
    sides: [][]u8 = undefined,

    pub fn init(allocator: Allocator, input: []const u8) !GardenMap {
        var instance = GardenMap{};

        var row_it = std.mem.splitSequence(u8, input, "\n");

        instance.cols = row_it.peek().?.len + 2;
        instance.rows = 2;
        while (row_it.next()) |_| : (instance.rows += 1) {}
        row_it.reset();

        // log.info("map size {d} × {d}", .{ instance.rows, instance.cols });

        instance.buffer = try allocator.alloc([]u8, instance.cols);
        instance.processed = try allocator.alloc([]bool, instance.cols);
        instance.sides = try allocator.alloc([]u8, instance.cols);
        for (0..instance.cols) |x| {
            instance.buffer[x] = try allocator.alloc(u8, instance.rows);
            instance.processed[x] = try allocator.alloc(bool, instance.rows);
            instance.sides[x] = try allocator.alloc(u8, instance.rows);
            var row: ?[]const u8 = null;
            if (x > 0) row = row_it.next();
            for (0..instance.rows) |y| {
                instance.buffer[x][y] = ' ';
                if (row != null and y > 0 and y < instance.rows - 1) {
                    instance.buffer[x][y] = row.?[y - 1];
                }
                instance.processed[x][y] = false;
                instance.sides[x][y] = ' ';
            }
        }

        return instance;
    }

    pub fn animate(self: *GardenMap) void {
        for (0..self.buffer.len) |y| {
            for (0..self.buffer[y].len) |x| {
                std.debug.print(t.yx, .{ 2 + y, 10 + self.buffer[0].len * 2 + x * 2 });
                std.debug.print("{c} ", .{self.buffer[y][x]});
            }
        }

        for (0..self.buffer.len) |y| {
            for (0..self.buffer[y].len) |x| {
                std.debug.print(t.yx, .{ 2 + y, 20 + self.buffer[0].len * 4 + x * 2 });
                const v = self.processed[y][x];
                switch (v) {
                    true => std.debug.print("X ", .{}),
                    false => std.debug.print(". ", .{}),
                }
            }
        }

        std.debug.print(t.yx, .{ self.buffer.len, self.buffer[0].len });
        std.debug.print("\n\n", .{});
    }

    pub fn findRegions(self: *GardenMap, allocator: Allocator) ![]Region {
        // log.info(t.hide_cursor, .{});
        // log.info(t.clear_screen, .{});

        var regions = std.array_list.Managed(Region).init(allocator);
        var all_points = VectorSet(2, usize).init(allocator);

        for (0..self.buffer.len) |y| {
            for (0..self.buffer[0].len) |x| {
                if (self.buffer[y][x] == ' ') continue;
                try all_points.insert(.{ x, y });
            }
        }

        var all_points_it = all_points.iterator();
        while (all_points_it.next()) |point| {
            if (self.processed[point[1]][point[0]]) continue;

            var region = try Region.init(allocator, self.buffer[point[1]][point[0]]);
            var perimeter_positions = VectorSet(2, isize).init(allocator);

            var q = std.array_list.Managed(@Vector(2, usize)).init(allocator);
            defer q.deinit();
            try q.append(point.*);

            while (q.items.len > 0) {
                const curr = q.pop().?;
                if (region.tiles.contains(curr)) {
                    continue;
                }
                try region.tiles.insert(curr);
                region.area += 1;

                // region.animate(.{ 2, 2 });
                // self.animate();
                // aoc.blockAskForNext();

                const neighbours = [_]@Vector(2, isize){
                    @as(@Vector(2, isize), @intCast(curr)) +| @Vector(2, isize){ 0, -1 },
                    @as(@Vector(2, isize), @intCast(curr)) +| @Vector(2, isize){ 1, 0 },
                    @as(@Vector(2, isize), @intCast(curr)) +| @Vector(2, isize){ 0, 1 },
                    @as(@Vector(2, isize), @intCast(curr)) +| @Vector(2, isize){ -1, 0 },
                };
                for (0..neighbours.len) |i| {
                    const n = neighbours[i];
                    if (n[0] < 0 or n[1] < 0 or n[0] >= self.buffer[0].len or n[1] >= self.buffer.len) {
                        region.perimeter += 1;
                        try perimeter_positions.insert(n);
                        continue;
                    }
                    if (self.buffer[@intCast(n[1])][@intCast(n[0])] != region.label) {
                        region.perimeter += 1;
                        try perimeter_positions.insert(n);
                        continue;
                    }
                    try q.append(@Vector(2, usize){ @intCast(n[0]), @intCast(n[1]) });
                }
            }

            var visited = VectorSet(3, isize).init(allocator);
            var perimeter_dir_positions = VectorSet(3, isize).init(allocator);
            var perimeter_pos_it = perimeter_positions.iterator();
            while (perimeter_pos_it.next()) |p| {
                inline for (std.meta.fields(Dir)) |d| {
                    const tile = p.* + @as(Dir, @enumFromInt(d.value)).toVec();
                    if (tile[0] > 0 and tile[1] > 0 and region.tiles.contains(@intCast(tile))) {
                        try perimeter_dir_positions.insert(@Vector(3, isize){ p[0], p[1], d.value });
                    }
                }
            }
            var perimeter_dir_pos_it = perimeter_dir_positions.iterator();

            var sides: usize = 0;

            self.cleanSidesMap();
            while (perimeter_dir_pos_it.next()) |curr| {
                if (visited.contains(curr.*)) continue;
                sides += 1;

                var nq = std.array_list.Managed(@Vector(3, isize)).init(allocator);
                try nq.append(curr.*);
                defer nq.deinit();

                while (nq.items.len > 0) {
                    const next_n = nq.pop().?;
                    if (visited.contains(next_n)) continue;

                    // self.sides[@intCast(next_n[1])][@intCast(next_n[0])] = 'X';
                    // std.debug.print("\nSides: {d}", .{sides});
                    // self.printSidesMap();
                    // aoc.blockAskForNext();

                    try visited.insert(next_n);
                    const neighbours = [_]@Vector(3, isize){
                        @as(@Vector(3, isize), @intCast(next_n)) +| @Vector(3, isize){ -1, 0, 0 },
                        @as(@Vector(3, isize), @intCast(next_n)) +| @Vector(3, isize){ 0, -1, 0 },
                        @as(@Vector(3, isize), @intCast(next_n)) +| @Vector(3, isize){ 1, 0, 0 },
                        @as(@Vector(3, isize), @intCast(next_n)) +| @Vector(3, isize){ 0, 1, 0 },
                    };
                    for (0..neighbours.len) |i| {
                        const n = neighbours[i];
                        if (perimeter_dir_positions.contains(n) and
                            (n[0] == curr[0] or n[1] == curr[1]))
                        {
                            try nq.append(n);
                        }
                    }
                }
            }

            region.sides = sides;
            // log.info("# Sides: {d}", .{region.sides});

            var tile_it = region.tiles.iterator();
            while (tile_it.next()) |tile| {
                self.processed[tile[1]][tile[0]] = true;
            }
            try regions.append(region);
        }

        return regions.items;
    }

    pub fn cleanSidesMap(self: *GardenMap) void {
        for (0..self.cols) |x| {
            for (0..self.rows) |y| {
                self.sides[x][y] = ' ';
            }
        }
    }

    pub fn printSidesMap(self: *GardenMap) void {
        for (0..self.cols) |x| {
            log.info("\n ", .{});
            for (0..self.rows) |y| {
                log.info("{c} ", .{self.sides[x][y]});
            }
        }
    }

    pub fn format(self: GardenMap, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                try writer.print("{c}", .{self.buffer[x][y]});
            }
        }
        try writer.print("\n\n", .{});

        var colour: usize = 20;
        for (0..self.cols) |x| {
            try writer.print("\n ", .{});
            for (0..self.rows) |y| {
                try writer.print(t.bg_color, .{colour});
                if (self.processed[x][y]) {
                    try writer.print("X ", .{});
                } else {
                    try writer.print(". ", .{});
                }
                try writer.print("{s}", .{t.clear});
            }
            colour += 1;
        }
        try writer.print("\n\n", .{});
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !GardenMap {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    const garden_map = try GardenMap.init(allocator, trimmed);
    return garden_map;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var garden_map = try parseInput(allocator, input);
    const regions = try garden_map.findRegions(allocator);

    var total_prize: usize = 0;
    for (0..regions.len) |i| {
        // log.info("{any}", .{regions[i]});
        const region_price = try regions[i].calculatePriceWithPerimeter();
        total_prize += region_price;
    }
    std.debug.print("\nResult: {d}", .{total_prize});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var garden_map = try parseInput(allocator, input);
    const regions = try garden_map.findRegions(allocator);

    var total_prize: usize = 0;
    for (0..regions.len) |i| {
        // log.info("{any}", .{regions[i]});
        const region_price = try regions[i].calculatePriceWithSides();
        total_prize += region_price;
    }
    std.debug.print("\nResult: {d}", .{total_prize});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
