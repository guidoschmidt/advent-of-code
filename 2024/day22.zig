const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 22;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8) !std.ArrayList(usize) {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, trimmed, "\n");
    var buyer_numbers = std.ArrayList(usize).init(allocator);
    while (it.next()) |row| {
        const num = try std.fmt.parseInt(usize, row, 10);
        try buyer_numbers.append(num);
    }
    return buyer_numbers;
}

fn mix(in: usize, val: usize) usize {
    return in ^ val;
}

fn prune(in: usize) usize {
    return @mod(in, 16777216);
}

fn generateSecretNumber(start: usize) usize {
    var tmp = start * 64;
    tmp = mix(start, tmp);
    tmp = prune(tmp);

    const div = @divFloor(tmp, 32);
    tmp = mix(tmp, div);
    tmp = prune(tmp);

    const mul = tmp * 2048;
    tmp = mix(tmp, mul);
    tmp = prune(tmp);

    return tmp;
}

fn evolveSecretNumber(start: usize, it_count: usize, result: *usize) void {
    var next = start;
    for (0..it_count) |_| {
        next = generateSecretNumber(next);
    }
    result.* += next;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const buyer_numbers = try parseInput(allocator, input);
    var result: usize = 0;

    for (buyer_numbers.items) |num| {
        const t = try std.Thread.spawn(.{}, evolveSecretNumber, .{ num, 2000, &result });
        t.join();
    }

    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

test "mix test" {
    const in: usize = 42;
    const result = mix(in, 15);
    try std.testing.expectEqual(@as(usize, 37), result);
}

test "prune test" {
    const in: usize = 100000000;
    const result = prune(in);
    try std.testing.expectEqual(@as(usize, 16113920), result);
}

test "secret number test" {
    var start: usize = 123;
    const expected = [_]usize{
        15887950,
        16495136,
        527345,
        704524,
        1553684,
        12683156,
        11100544,
        12249484,
        7753432,
        5908254,
    };
    for (0..expected.len) |i| {
        const result = generateSecretNumber(start);
        try std.testing.expectEqual(@as(usize, expected[i]), result);
        start = result;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
