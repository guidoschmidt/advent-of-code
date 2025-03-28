const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");
const Graph = @import("./Graph.zig");

const DAY: u8 = 23;
const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    computers: std.BufSet,
    links: std.StringHashMap(std.BufSet),
};

fn parseInput(allocator: Allocator, input: []const u8, double_linked: bool) !ParseResult {
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

        if (!links.contains(a)) {
            try links.put(a, std.BufSet.init(allocator));
        }

        if (links.getPtr(a)) |aptr| {
            try aptr.insert(b);
        }
        if (double_linked) {
            if (links.getPtr(b)) |bptr| {
                try bptr.insert(a);
            }
        }
    }

    return ParseResult{ .computers = computers, .links = links };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input, true);

    var triples = std.BufSet.init(allocator);
    var computer_it = parsed.computers.iterator();
    while (computer_it.next()) |a| {
        var al_it = parsed.links.get(a.*).?.iterator();
        while (al_it.next()) |al| {
            var bl_it = parsed.links.get(al.*).?.iterator();
            while (bl_it.next()) |bl| {
                if (parsed.links.get(a.*).?.contains(bl.*)) {
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

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input, false);

    var graph = Graph.init(allocator);

    var computer_it = parsed.computers.iterator();
    while (computer_it.next()) |computer| {
        if (parsed.links.get(computer.*)) |links| {
            var link_it = links.iterator();
            while (link_it.next()) |link| {
                try graph.addLink(computer.*, link.*);
            }
        }
    }

    log.info("{any}", .{graph});
    try graph.toDotFile(allocator);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
