const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 5;
const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    updates: *std.ArrayList([]usize),
    ordering_rules: *std.ArrayList(@Vector(2, usize)),
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    const cleaned = std.mem.trimRight(u8, input, "\n");

    var updates = std.ArrayList([]usize).init(allocator);
    var ordering_rules = std.ArrayList(@Vector(2, usize)).init(allocator);

    var row_it = std.mem.split(u8, cleaned, "\n");
    while (row_it.next()) |row| {
        // log.info("{s}", .{row});
        if (std.mem.containsAtLeast(u8, row, 1, "|")) {
            var num_it = std.mem.split(u8, row, "|");
            const vec: @Vector(2, usize) = .{
                try std.fmt.parseInt(usize, num_it.next().?, 10),
                try std.fmt.parseInt(usize, num_it.next().?, 10),
            };
            try ordering_rules.append(vec);
        }

        if (std.mem.containsAtLeast(u8, row, 1, ",")) {
            var num_it = std.mem.split(u8, row, ",");
            var num_list = std.ArrayList(usize).init(allocator);
            while (num_it.next()) |num_str| {
                const num = try std.fmt.parseInt(usize, num_str, 10);
                try num_list.append(num);
            }
            try updates.append(num_list.items);
        }
    }

    return ParseResult{
        .updates = &updates,
        .ordering_rules = &ordering_rules,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);

    var center_values: @Vector(1000, usize) = @splat(0);
    var i: usize = 0;
    while (parsed.updates.items.len > 0) : (i += 1) {
        const next = parsed.updates.pop();

        // log.info("ROW: {any}", .{next});
        var valid = true;
        for (0..parsed.ordering_rules.items.len) |j| {
            const first = parsed.ordering_rules.items[j][0];
            const second = parsed.ordering_rules.items[j][1];
            const idx_first = std.mem.indexOf(usize, next, &[1]usize{first});
            const idx_second = std.mem.indexOf(usize, next, &[1]usize{second});
            if (idx_first != null and idx_second != null) {
                valid = valid and idx_first.? < idx_second.?;
                // log.info("   → {any} {d} [{?}] | {d} [{?}]", .{ valid, first, idx_first, second, idx_second });
            }
        }

        if (valid) {
            const center = next.len / 2;
            // log.info("    > {d}", .{next[center]});
            center_values[i] = next[center];
        }
    }

    const result = @reduce(.Add, center_values);
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = input; // autofix
    _ = allocator; // autofix
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
