const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const Allocator = std.mem.Allocator;
const log = std.log;
const vector_count: usize = 20;

const ParseResult = struct {
    row_count: usize,
    reports: std.array_list.Managed(@Vector(vector_count, isize)),
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    var row_it = std.mem.splitSequence(u8, input, "\n");
    var row_count: usize = 0;
    while (row_it.next()) |row| {
        if (row.len == 0) break;
        row_count += 1;
    }
    row_it.reset();
    // log.info("Row count: {d}", .{row_count});

    var reports = std.array_list.Managed(@Vector(vector_count, isize)).init(allocator);

    var i: usize = 0;
    while (row_it.next()) |row| : (i += 1) {
        if (row.len == 0) break;
        var level_it = std.mem.splitSequence(u8, row, " ");
        try reports.append(@splat(0));
        var j: usize = 0;
        while (level_it.next()) |level| : (j += 1) {
            if (level.len == 0) break;
            const clean = std.mem.trim(u8, level, " ");
            const num = try std.fmt.parseInt(isize, clean, 10);
            reports.items[i][j] = num;
        }
    }

    return ParseResult{
        .row_count = row_count,
        .reports = reports,
    };
}

fn checkRow(row: @Vector(vector_count, isize)) bool {
    var sign_sum: isize = 0;
    var previous_num: isize = row[0];
    var num = row[1];
    var is_safe = true;
    var j: usize = 1;
    //log.info("{any}", .{row});
    while (true) : (j += 1) {
        num = row[j];
        if (num == 0) break;
        var diff = previous_num - num;
        const sign = std.math.sign(diff);
        if (j > 0) {
            diff = @intCast(@abs(diff));
            if (diff >= 1 and diff <= 3) {
                is_safe = is_safe and true;
            } else {
                is_safe = is_safe and false;
            }
        }
        sign_sum += @intCast(sign);
        previous_num = num;
    }
    //log.info("Sign sum: {d}", .{sign_sum});
    if (@abs(sign_sum) < j - 1)
        is_safe = false;

    return is_safe;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);

    var safe_list = std.array_list.Managed(bool).init(allocator);

    for (0..parsed.reports.items.len) |i| {
        const row = parsed.reports.items[i];
        const is_safe = checkRow(row);
        try safe_list.append(is_safe);
    }

    var count: usize = 0;
    for (0..parsed.row_count) |i| {
        // log.info("{d} [safe? {any}]", .{ parsed.reports.items[i], safe_list.items[i] });
        if (safe_list.items[i])
            count += 1;
    }
    std.debug.print("Result: {d}", .{count});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);

    var safe_list = std.array_list.Managed(bool).init(allocator);

    for (0..parsed.reports.items.len) |i| {
        const row = parsed.reports.items[i];
        var is_safe = checkRow(row);
        if (is_safe) {
            try safe_list.append(is_safe);
            continue;
        }
        // log.info("> {d}", .{row});

        for (0..vector_count) |r| {
            if (row[r] == 0) break;
            var adjusted: @Vector(vector_count, isize) = @splat(0);
            var v: usize = 0;
            for (0..vector_count) |u| {
                if (r == u) continue;
                adjusted[v] = row[u];
                v += 1;
            }
            is_safe = checkRow(adjusted);
            // log.info("    ADJ: {d} --> [{any}]", .{ adjusted, is_safe });
            if (is_safe) break;
        }

        try safe_list.append(is_safe);
    }

    var count: usize = 0;
    for (0..parsed.row_count) |i| {
        // log.info("{d} [safe? {any}]", .{ parsed.reports.items[i], safe_list.items[i] });
        if (safe_list.items[i])
            count += 1;
    }
    std.debug.print("Result: {d}", .{count});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, 2, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, 2, .PUZZLE, part2);
}
