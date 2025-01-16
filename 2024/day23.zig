const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 23;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8) !void {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, trimmed, "\n");

    var computers = std.BufSet.init(allocator);
    var links = std.StringHashMap(std.BufSet).init(allocator);

    var idx: usize = 0;
    while (it.next()) |row| : (idx += 1) {
        var split_it = std.mem.splitSequence(u8, row, "-");
        const a = split_it.next().?;
        const b = split_it.next().?;

        try computers.insert(a);
        try computers.insert(b);

        if (links.contains(a)) {
            var bufset = links.get(a).?;
            try bufset.insert(b);
            try links.put(a, bufset);
        } else {
            try links.put(a, std.BufSet.init(allocator));
            var bufset = links.get(a).?;
            try bufset.insert(b);
            try links.put(a, bufset);
        }

        if (links.contains(b)) {
            var bufset = links.get(b).?;
            try bufset.insert(a);
            try links.put(b, bufset);
        } else {
            try links.put(b, std.BufSet.init(allocator));
            var bufset = links.get(b).?;
            try bufset.insert(a);
            try links.put(b, bufset);
        }
    }

    var triples = std.BufSet.init(allocator);
    var computer_it = computers.iterator();
    while (computer_it.next()) |a| {
        var al_it = links.get(a.*).?.iterator();
        while (al_it.next()) |al| {
            var bl_it = links.get(al.*).?.iterator();
            while (bl_it.next()) |bl| {
                if (links.get(a.*).?.contains(bl.*)) {
                    var names = [_][]const u8{ a.*, al.*, bl.* };

                    std.mem.sort([]const u8, &names, {}, comptime struct {
                        pub fn f(_: void, lhs: []const u8, rhs: []const u8) bool {
                            return std.mem.order(u8, lhs, rhs) == .lt;
                        }
                    }.f);

                    if (names[0][0] == 't' or names[1][0] == 't' or names[2][0] == 't') {
                        var buf: [8]u8 = undefined;
                        const triple = try std.fmt.bufPrint(&buf, "{s},{s},{s}", .{ names[0], names[1], names[2] });

                        try triples.insert(triple);
                    }
                }
            }
        }
    }

    const result: usize = triples.count();
    std.debug.print("\nResult: {d}", .{result});
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    try parseInput(allocator, input);
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
