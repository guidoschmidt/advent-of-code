const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 7;

const Allocator = std.mem.Allocator;
const log = std.log;

const Map = struct {
    rows: usize,
    cols: usize,
    buffer: []u8,

    pub fn init(allocator: Allocator, buffer: []const u8) !Map {
        if (std.mem.indexOf(u8, buffer, "\n")) |line_end| {
            return .{
                .buffer = try std.mem.replaceOwned(u8, allocator, buffer, "\n", ""),
                .cols = line_end,
                .rows = (buffer.len - 1) / line_end,
            };
        }
        @panic("Failed to split input buffer!");
    }

    pub fn get(self: *const Map, x: usize, y: usize) u8 {
        return self.buffer[(y * self.cols) + x];
    }

    pub fn format(self: Map, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Map {d} x {d}\n", .{ self.rows, self.cols });
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                try writer.print("{c}", .{self.get(x, y)});
            }
            try writer.print("\n", .{});
        }
    }

    pub fn deinit(self: Map, allocator: Allocator) void {
        allocator.free(self.buffer);
    }
};

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("example-07");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    const map: Map = try .init(allocator, input);

    var start: @Vector(2, usize) = @splat(0);
    var splitters: std.array_list.Managed(@Vector(2, usize)) = .init(allocator);

    for (0..map.rows) |y| {
        for (0..map.cols) |x| {
            switch (map.get(x, y)) {
                'S' => start = .{ x, y },
                '^' => try splitters.append(.{ x, y }),
                else => continue,
            }
        }
    }
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    const input = @embedFile("puzzle-07");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    // try aoc.runPart(allocator, part2);
}
