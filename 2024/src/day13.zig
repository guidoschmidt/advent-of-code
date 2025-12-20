const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 13;
const Allocator = std.mem.Allocator;
const log = std.log;

const Machine = struct {
    idx: usize = 0,
    a: @Vector(2, usize),
    b: @Vector(2, usize),
    prize: @Vector(2, usize),

    pub fn optimize(self: *Machine, limit: usize) usize {
        var a: usize = 1;
        var b: usize = 1;
        var minimized_tokens: usize = Machine.tokenize(limit, limit);
        const vec_type = @TypeOf(self.a);
        var foundSolution: bool = false;
        const step: usize = 1;
        while (a <= limit) : (a += step) {
            b = 1;
            while (b <= limit) : (b += step) {
                const evaluation = @as(vec_type, @splat(a)) * self.a + @as(vec_type, @splat(b)) * self.b;
                const solution = @reduce(.And, evaluation == self.prize);
                if (solution) {
                    foundSolution = true;
                    log.info("{s}{d} == {d}", .{ t.green, evaluation, self.prize });
                    const tokens = Machine.tokenize(a, b);
                    log.info("    {d} x {d}", .{ a, b });
                    log.info("    → {d}", .{tokens});
                    if (tokens < minimized_tokens) {
                        minimized_tokens = tokens;
                    }
                    log.info("{s}", .{t.clear});
                }
            }
        }
        return if (foundSolution) minimized_tokens else 0;
    }

    pub fn tokenize(a: usize, b: usize) usize {
        return a * 3 + b * 1;
    }

    pub fn format(self: Machine, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Machine {d}\n", .{self.idx});
        try writer.print("  A: {d}\n", .{self.a});
        try writer.print("  B: {d}\n", .{self.b});
        try writer.print("  Prize: {d}\n", .{self.prize});
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.array_list.Managed(Machine) {
    const trimmed = std.mem.trimRight(u8, input, "\n");

    var machines = std.array_list.Managed(Machine).init(allocator);
    var machines_it = std.mem.splitSequence(u8, trimmed, "\n\n");
    var idx: usize = 0;
    while (machines_it.next()) |machine_str| : (idx += 1) {
        var row_it = std.mem.splitSequence(u8, machine_str, "\n");

        var button_a = row_it.next().?[12..];
        button_a = try std.mem.replaceOwned(u8, allocator, button_a, "\n", "");
        button_a = try std.mem.replaceOwned(u8, allocator, button_a, "X+", "");
        button_a = try std.mem.replaceOwned(u8, allocator, button_a, "Y+", "");
        var button_a_it = std.mem.splitSequence(u8, button_a, ", ");

        var button_b = row_it.next().?[12..];
        button_b = try std.mem.replaceOwned(u8, allocator, button_b, "\n", "");
        button_b = try std.mem.replaceOwned(u8, allocator, button_b, "X+", "");
        button_b = try std.mem.replaceOwned(u8, allocator, button_b, "Y+", "");
        var button_b_it = std.mem.splitSequence(u8, button_b, ", ");

        var prize = row_it.next().?[7..];
        prize = try std.mem.replaceOwned(u8, allocator, prize, "\n", "");
        prize = try std.mem.replaceOwned(u8, allocator, prize, "X=", "");
        prize = try std.mem.replaceOwned(u8, allocator, prize, "Y=", "");
        var prize_it = std.mem.splitSequence(u8, prize, ", ");

        const machine = Machine{
            .idx = idx,
            .a = @Vector(2, usize){
                try std.fmt.parseInt(usize, button_a_it.next().?, 10),
                try std.fmt.parseInt(usize, button_a_it.next().?, 10),
            },
            .b = @Vector(2, usize){
                try std.fmt.parseInt(usize, button_b_it.next().?, 10),
                try std.fmt.parseInt(usize, button_b_it.next().?, 10),
            },
            .prize = @Vector(2, usize){
                try std.fmt.parseInt(usize, prize_it.next().?, 10),
                try std.fmt.parseInt(usize, prize_it.next().?, 10),
            },
        };
        // log.info("{any}", .{machine});
        try machines.append(machine);
    }

    return machines;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const machines = try parseInput(allocator, input);
    var result: usize = 0;
    for (machines.items) |*machine| {
        const min_tokens = machine.optimize(100);
        result += min_tokens;
    }
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    // Actually it's just a matter of solving a linear equation:
    // https://www.reddit.com/r/adventofcode/comments/1hdlc1k/2024_day_13_part_2_anyone_else_just_didnt_find
    const machines = try parseInput(allocator, input);
    var result: isize = 0;
    for (machines.items) |*machine| {
        const a: @Vector(2, f64) = @floatFromInt(machine.a);
        const b: @Vector(2, f64) = @floatFromInt(machine.b);
        var prize: @Vector(2, f64) = @floatFromInt(machine.prize);
        prize[0] += 10000000000000;
        prize[1] += 10000000000000;

        const times_b = (prize[1] * a[0] - prize[0] * a[1]) / (b[1] * a[0] - b[0] * a[1]);
        const times_a = (prize[0] - b[0] * times_b) / a[0];

        // std.log.info("{d}, {d}, {d}", .{ a, b, prize });
        // std.log.info("{d} [{any}]", .{ times_b, @mod(times_b, 1) });
        // std.log.info("{d} [{any}]", .{ times_a, @mod(times_a, 1) });

        if (@mod(times_a, 1) == 0.0 and @mod(times_b, 1) == 0.0) {
            result +=
                @as(isize, @intFromFloat(@trunc(times_a))) * 3 +
                @as(isize, @intFromFloat(@trunc(times_b)));
        }
    }
    std.debug.print("\nResult: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
