const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

const Brick = struct {
    a: @Vector(3, u16),
    b: @Vector(3, u16),

    pub fn format(self: Brick,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n[{d}, {d}, {d}] - [{d}, {d}, {d}]",
                         .{ self.a[0], self.a[1], self.a[2], self.b[0], self.b[1], self.b[2] });
    }
};

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var brick_list = std.ArrayList(Brick).init(gpa);

    var row_it = std.mem.tokenize(u8, input, "\n");
    while(row_it.next()) |row| {
        var pos_it = std.mem.tokenize(u8, row, "~");
        const start_str = pos_it.next().?;
        var start_it = std.mem.tokenize(u8, start_str, ",");
        var start: @Vector(3, u16) = undefined;
        var i: usize = 0;
        while(start_it.next()) |n| : (i += 1) {
            const num = try std.fmt.parseInt(u16, n, 10);
            start[i] = num;
        }

        const end_str = pos_it.next().?;
        var end_it = std.mem.tokenize(u8, end_str, ",");
        var end: @Vector(3, u16) = undefined;
        i = 0;
        while(end_it.next()) |n| : (i += 1) {
            const num = try std.fmt.parseInt(u16, n, 10);
            end[i] = num;
        }

        try brick_list.append(Brick {
            .a = start,
            .b = end,
        });
    }

    for(brick_list.items) |brick| {
        std.debug.print("\n{any}", .{ brick });
    }
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = input;
    _ = gpa;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try aoc.runPart(gpa, 2023, 22, .EXAMPLE, part1);
    try aoc.runPart(gpa, 2023, 22, .EXAMPLE, part2);
}
