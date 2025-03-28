const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 7;
const Allocator = std.mem.Allocator;
const log = std.log;

const Op = enum(u1) {
    ADD = 0,
    MUL = 1,

    pub fn format(self: Op, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .ADD => try writer.print("{c}", .{'+'}),
            .MUL => try writer.print("{c}", .{'*'}),
        }
    }
};

const Equation = struct {
    result: usize,
    number_count: usize,
    numbers: []usize,

    pub fn format(self: Equation, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d} = ", .{self.result});
        for (self.numbers) |number| {
            try writer.print("{d} ", .{
                number,
            });
        }
        try writer.print(" [{d}]", .{self.number_count});
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.ArrayList(Equation) {
    const clean = std.mem.trimRight(u8, input, "\n");
    var row_it = std.mem.splitSequence(u8, clean, "\n");

    var equations = std.ArrayList(Equation).init(allocator);

    while (row_it.next()) |row| {
        var eq_it = std.mem.splitSequence(u8, row, " ");

        var number_count: usize = 0;
        while (eq_it.next()) |_| : (number_count += 1) {}
        eq_it.reset();

        const result_str = std.mem.trim(u8, eq_it.next().?, ":");
        const result = try std.fmt.parseInt(usize, result_str, 10);

        const numbers = try allocator.alloc(usize, number_count - 1);
        var i: usize = 0;
        while (eq_it.next()) |str| : (i += 1) {
            const trimmed = std.mem.trim(u8, str, " ");
            const num = try std.fmt.parseInt(usize, trimmed, 10);
            numbers[i] = num;
        }

        try equations.append(Equation{ .result = result, .numbers = numbers, .number_count = i });
    }

    return equations;
}

fn solveTree(depth: usize, needed_result: usize, result: usize, numbers: []usize) bool {
    if (depth >= numbers.len) {
        return result == needed_result;
    }
    return solveTree(depth + 1, needed_result, result + numbers[depth], numbers) or
        solveTree(depth + 1, needed_result, result * numbers[depth], numbers);
}

fn solveTreeWithConcat(depth: usize, needed_result: usize, result: usize, numbers: []usize) bool {
    if (depth >= numbers.len) {
        return result == needed_result;
    }
    return solveTreeWithConcat(depth + 1, needed_result, result + numbers[depth], numbers) or
        solveTreeWithConcat(depth + 1, needed_result, result * numbers[depth], numbers) or
        solveTreeWithConcat(depth + 1, needed_result, concatNumbers(result, numbers[depth]), numbers);
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const equations = try parseInput(allocator, input);

    var result: usize = 0;

    for (0..equations.items.len) |i| {
        const eq = equations.items[i];
        const is_valid = solveTree(1, eq.result, eq.numbers[0], eq.numbers);
        if (is_valid)
            result += eq.result;
    }

    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const equations = try parseInput(allocator, input);

    var result: usize = 0;

    for (0..equations.items.len) |i| {
        const eq = equations.items[i];
        const is_valid = solveTreeWithConcat(1, eq.result, eq.numbers[0], eq.numbers);
        if (is_valid)
            result += eq.result;
    }

    std.debug.print("\nResult: {d}", .{result});
}

fn concatNumbers(lhs: usize, rhs: usize) usize {
    const digits_b = countDigits(usize, rhs, 5) catch unreachable;
    return (lhs * std.math.pow(usize, 10, digits_b)) + rhs;
}

fn countDigits(comptime T: type, n: T, comptime max: T) !T {
    inline for (1..max) |i| {
        if (n < std.math.pow(T, 10, i)) return i;
    }
    unreachable;
}

test "Test concatenation operator" {
    var lhs: usize = 9;
    var rhs: usize = 2;
    try std.testing.expectEqual(@as(usize, 92), concatNumbers(lhs, rhs));
    lhs = 13;
    rhs = 75;
    try std.testing.expectEqual(@as(usize, 1375), concatNumbers(lhs, rhs));
    lhs = 123;
    rhs = 45;
    try std.testing.expectEqual(@as(usize, 12345), concatNumbers(lhs, rhs));
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
