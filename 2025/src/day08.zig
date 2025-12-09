const std = @import("std");
const aoc = @import("aoc");
const VectorSet = @import("libs").VectorSet;

const DAY: u5 = 8;

const Allocator = std.mem.Allocator;
const log = std.log;

fn distance(comptime T: type, a: @Vector(3, T), b: @Vector(3, T)) T {
    const v = @abs(b - a);
    return @sqrt(@reduce(.Add, v * v));
}

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("example-08");

    var reader: std.Io.Reader = .fixed(input);

    const T: type = f32;
    const Box = struct {
        id: usize,
        pos: @Vector(3, T),

        pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("[{d: >4}] {d: >6}", .{ self.id, self.pos });
        }
    };

    var junction_boxes: std.array_list.Managed(Box) = .init(allocator);
    defer junction_boxes.deinit();

    var idx: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        var coords_it = std.mem.splitScalar(u8, line, ',');
        var coord: @Vector(3, T) = @splat(0);
        var i: usize = 0;
        while (coords_it.next()) |str| : (i += 1) {
            const v = try std.fmt.parseFloat(T, str);
            std.debug.assert(v != 0);
            coord[i] = v;
        }
        std.debug.assert(i <= 3);
        try junction_boxes.append(.{
            .id = idx,
            .pos = coord,
        });
        idx += 1;
    }

    const Connection = struct {
        a: Box,
        b: Box,
        d: T,

        pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("{f}---{f} [distance: {d: >10.3}]", .{ self.a, self.b, self.d });
        }
    };

    var connections: std.array_list.Managed(Connection) = .init(allocator);
    defer connections.deinit();

    for (0..junction_boxes.items.len) |i| {
        for (i..junction_boxes.items.len) |j| {
            const a = junction_boxes.items[i];
            const b = junction_boxes.items[j];
            const d = distance(T, a.pos, b.pos);
            if (d == 0) continue;
            try connections.append(.{
                .a = a,
                .b = b,
                .d = d,
            });
        }
    }

    std.mem.sort(Connection, connections.items, {}, comptime struct {
        pub fn f(_: void, a: Connection, b: Connection) bool {
            return a.d > b.d;
        }
    }.f);

    while (connections.pop()) |next| {
        std.debug.print("{f}\n", .{next});
    }

    // std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});
}

fn part2(allocator: Allocator) anyerror!void {
    _ = allocator;
    // const input = @embedFile("example-08");
    // std.debug.print("--- INPUT---\n{s}\n------------\n", .{@embedFile()});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    // try aoc.runPart(allocator, part2);
}
