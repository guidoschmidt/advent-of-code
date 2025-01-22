const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 5;
const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    updates: std.ArrayList([]usize),
    ordering_rules: std.ArrayList(@Vector(2, usize)),
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    const cleaned = std.mem.trimRight(u8, input, "\n");

    var updates = std.ArrayList([]usize).init(allocator);
    var ordering_rules = std.ArrayList(@Vector(2, usize)).init(allocator);

    var row_it = std.mem.splitSequence(u8, cleaned, "\n");
    while (row_it.next()) |row| {
        // log.info("{s}", .{row});
        if (std.mem.containsAtLeast(u8, row, 1, "|")) {
            var num_it = std.mem.splitSequence(u8, row, "|");
            const vec: @Vector(2, usize) = .{
                try std.fmt.parseInt(usize, num_it.next().?, 10),
                try std.fmt.parseInt(usize, num_it.next().?, 10),
            };
            try ordering_rules.append(vec);
        }

        if (std.mem.containsAtLeast(u8, row, 1, ",")) {
            var num_it = std.mem.splitSequence(u8, row, ",");
            var num_list = std.ArrayList(usize).init(allocator);
            while (num_it.next()) |num_str| {
                const num = try std.fmt.parseInt(usize, num_str, 10);
                try num_list.append(num);
            }
            try updates.append(num_list.items);
        }
    }

    return ParseResult{
        .updates = updates,
        .ordering_rules = ordering_rules,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var parsed = try parseInput(allocator, input);

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

fn isValid(next: []usize, ordering_rules: *std.ArrayList(@Vector(2, usize))) bool {
    var valid = true;
    for (0..ordering_rules.items.len) |j| {
        const first = ordering_rules.items[j][0];
        const second = ordering_rules.items[j][1];
        const idx_first = std.mem.indexOf(usize, next, &[1]usize{first});
        const idx_second = std.mem.indexOf(usize, next, &[1]usize{second});
        if (idx_first != null and idx_second != null) {
            valid = valid and idx_first.? < idx_second.?;
        }
    }
    return valid;
}

fn reorder(next: []usize, ordering_rules: *std.ArrayList(@Vector(2, usize))) void {
    for (0..ordering_rules.items.len) |j| {
        const first = ordering_rules.items[j][0];
        const second = ordering_rules.items[j][1];

        const idx_first = std.mem.indexOf(usize, next, &[1]usize{first});
        const idx_second = std.mem.indexOf(usize, next, &[1]usize{second});
        if (idx_first != null and idx_second != null) {
            if (idx_first.? > idx_second.?) {
                log.info("[{d} | {d}] -- {d} . {d}", .{ first, second, idx_first.?, idx_second.? });
                const tmp = next[idx_second.?];
                for (idx_second.?..@min(next.len - 1, idx_first.? + 1)) |s| {
                    log.info("    {d} <- {d}", .{ s, s +| 1 });
                    next[s] = next[s + 1];
                }
                next[idx_first.?] = tmp;
                log.info("Re-sorted: {d}", .{next});
            }
        }
    }
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var parsed = try parseInput(allocator, input);

    var center_values: @Vector(1000, usize) = @splat(0);
    var i: usize = 0;
    while (parsed.updates.items.len > 0) : (i += 1) {
        const next = parsed.updates.pop();

        const valid = isValid(next, &parsed.ordering_rules);
        if (!valid) {
            log.info("Original:  {d}", .{next});

            while (!isValid(next, &parsed.ordering_rules)) {
                reorder(next, &parsed.ordering_rules);
            }

            const center = next.len / 2;
            log.info("Re-sorted: {d}", .{next});
            log.info("    > {d}", .{next[center]});
            center_values[i] = next[center];
        }
    }

    const result = @reduce(.Add, center_values);
    std.debug.print("\nResult: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
