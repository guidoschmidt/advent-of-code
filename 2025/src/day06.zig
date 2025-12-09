const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 6;

const Allocator = std.mem.Allocator;
const log = std.log;

const Cell = struct {
    value: []const u8 = " ",

    pub fn format(self: Cell, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{s}", .{self.value});
    }
};

fn part1(allocator: Allocator) anyerror!void {
    const input = std.mem.trimEnd(u8, @embedFile("puzzle-06"), "\n");

    const eol = std.mem.indexOf(u8, input, "\n").?;
    var first_line_reader: std.Io.Reader = .fixed(input[0..eol]);
    var column_count: usize = 1;
    var c = try first_line_reader.peekByte();
    while (true) {
        const next = first_line_reader.takeByte() catch break;
        if (c != ' ' and next == ' ') {
            column_count += 1;
        }
        c = next;
    }
    std.debug.print("Column count: {d}\n", .{column_count});

    var line_it = std.mem.splitSequence(u8, input, "\n");
    var row_count: usize = 0;
    while (line_it.next()) |_| {
        row_count += 1;
    }
    std.debug.print("{d} x {d}\n", .{ row_count, column_count });

    var ops: std.array_list.Managed(u8) = .init(allocator);
    defer ops.deinit();

    var problems = try allocator.alloc(std.array_list.Managed(u32), column_count);
    for (0..problems.len) |i| {
        problems[i] = .init(allocator);
    }
    defer allocator.free(problems);
    defer for (problems) |p| p.deinit();

    var lines_it: std.Io.Reader = .fixed(input);
    while (try lines_it.takeDelimiter('\n')) |line| {
        if (line.len == 0) continue;
        const line_trimmed = std.mem.trim(u8, line, "\n");
        var reader: std.Io.Reader = .fixed(line_trimmed);

        if (std.mem.containsAtLeast(u8, line_trimmed, 1, "+")) {
            var o: u8 = ' ';
            while (true) {
                o = reader.takeByte() catch break;
                switch (o) {
                    '*', '+' => try ops.append(o),
                    ' ' => continue,
                    else => unreachable,
                }
            }
            break;
        }

        var it = std.mem.splitScalar(u8, line, ' ');
        var i: usize = 0;
        while (it.next()) |next| {
            if (next.len == 0) continue;
            const v = try std.fmt.parseInt(u32, next, 10);
            try problems[i].append(v);
            i += 1;
        }
    }

    var sum: u64 = 0;
    for (0..problems.len) |p| {
        std.debug.print("({c} ", .{ops.items[p]});
        for (problems[p].items) |v| std.debug.print("{d} ", .{v});
        var result: usize = 0;
        switch (ops.items[p]) {
            '+' => {
                for (problems[p].items) |v| result += v;
            },
            '*' => {
                result = 1;
                for (problems[p].items) |v| result *= v;
            },
            ' ' => break,
            else => unreachable,
        }
        std.debug.print(" = {d}", .{result});
        std.debug.print(")\n", .{});
        sum += result;
    }
    std.debug.print("\nResult: {d}\n", .{sum});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-06");
    var rows: usize = 0;
    var cols: usize = 0;
    var ops: std.array_list.Managed(u8) = .init(allocator);
    var splits: std.array_list.Managed([2]usize) = .init(allocator);

    // Find number of rows
    var line_it = std.mem.splitScalar(u8, input, '\n');
    var line: []const u8 = "";
    while (line_it.next()) |l| : (rows += 1) {
        if (l.len == 0) break;
        line = l;
    }

    // Find number of columns
    var ops_reader: std.Io.Reader = .fixed(line);
    var previous: u8 = try ops_reader.takeByte();
    var s: usize = 0;
    var i: usize = 0;
    var last_seen_op: u8 = previous;
    while (true) : (i += 1) {
        const c = ops_reader.takeByte() catch {
            // last split, intentionally create a larger end index
            cols += 1;
            try ops.append(last_seen_op);
            try splits.append(.{ s, s + 5 });
            break;
        };
        if (previous == ' ' and c != ' ') {
            try ops.append(last_seen_op);
            // store the last seen op to be available
            // when iterator has no more data
            last_seen_op = c;
            try splits.append(.{ s, i });
            s = i;
        }
        if (c == ' ') {
            previous = c;
            continue;
        }
        cols += 1;
    }

    std.debug.print("{d} x {d}\n", .{ rows, cols });

    // Process input
    var sum: usize = 0;
    for (ops.items, 0..cols) |op, x| {
        var sum_column: usize = 0;
        var line_idx: usize = 0;

        for (0..rows) |r| {
            var number: usize = 0;

            var digit_count: usize = 0;
            line_it.reset();
            while (line_it.next()) |l| {
                if (l.len == 0 or std.mem.containsAtLeast(u8, l, 1, "*")) break;
                const lower = splits.items[x][0];
                const upper = @min(splits.items[x][1], l.len);
                const slice = l[lower..upper];
                if (r >= slice.len) break;
                if (slice[r] != ' ') digit_count += 1;
            }

            line_it.reset();
            var pow: usize = std.math.pow(usize, 10, digit_count -| 1);
            while (line_it.next()) |l| : (line_idx += 1) {
                if (l.len == 0 or std.mem.containsAtLeast(u8, l, 1, "*")) break;
                const lower = splits.items[x][0];
                const upper = @min(splits.items[x][1], l.len);
                const slice = l[lower..upper];
                if (r >= slice.len) break;

                switch (slice[r]) {
                    '0'...'9' => |c| {
                        const digit = c - '0';
                        number += digit * pow;
                        pow /= 10;
                    },
                    else => continue,
                }
            }

            switch (op) {
                '*' => sum_column = @max(1, sum_column) * @max(1, number),
                '+' => sum_column += number,
                else => unreachable,
            }
        }

        sum += sum_column;
    }
    std.debug.print("Result: {d}\n", .{sum});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
