const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 3;
const VEC_SIZE = 1000;
const Allocator = std.mem.Allocator;
const log = std.log;

fn parseInput(allocator: Allocator, input: []const u8, conditionals: bool) !@Vector(VEC_SIZE, isize) {
    _ = allocator;
    const advance = "mul(XXX,XXX)".len;
    const start = "mul(";
    var sliding_win = std.mem.window(u8, input, advance, 1);
    var vec_mult: @Vector(VEC_SIZE, isize) = @splat(0);
    var instructions_enabled = true;

    var i: usize = 0;
    while (sliding_win.next()) |slice| {
        const cleaned = std.mem.trim(u8, slice, "\n");
        if (conditionals) {
            if (std.mem.indexOf(u8, cleaned, "do")) |idx_do| {
                if (idx_do + 4 < cleaned.len and
                    std.mem.eql(u8, cleaned[idx_do .. idx_do + 4], "do()"))
                {
                    instructions_enabled = true;
                }
                if (idx_do + 7 < cleaned.len and
                    std.mem.eql(u8, cleaned[idx_do .. idx_do + 7], "don't()"))
                {
                    instructions_enabled = false;
                }
            }
        }

        if (std.mem.indexOf(u8, cleaned, start)) |idx_front| {
            if (!std.mem.eql(u8, cleaned[idx_front .. idx_front + 4], start)) continue;
            if (!std.mem.containsAtLeast(u8, cleaned[idx_front + 4 ..], 1, ")")) continue;
            if (std.mem.indexOf(u8, cleaned[idx_front + 4 ..], ")")) |idx_end| {
                const instr = cleaned[idx_front .. idx_front + 4 + idx_end + 1];
                var split_it = std.mem.split(u8, instr[start.len .. instr.len - 1], ",");
                const a = split_it.next() orelse continue;
                const b = split_it.next() orelse continue;
                const clean_a = std.mem.trim(u8, a, " ");
                const clean_b = std.mem.trim(u8, b, " ");
                const num_a = std.fmt.parseInt(isize, clean_a, 10) catch continue;
                const num_b = std.fmt.parseInt(isize, clean_b, 10) catch continue;
                const mult = num_a * num_b;
                if (mult == vec_mult[i -| 1]) {
                    // log.info("{d} == {d} CONTINUE", .{ mult, vec_mult[i -| 1] });
                    continue;
                }
                if (conditionals and !instructions_enabled) {
                    continue;
                }
                vec_mult[i] = mult;
                i += 1;
                // log.info("[{d}] {s} → {d} * {d} = {d}", .{ i, instr, num_a, num_b, mult });
            }
        }
    }
    return vec_mult;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const vec_mult = try parseInput(allocator, input, false);

    const result = @reduce(.Add, vec_mult);
    std.debug.print("\nResult: {d}", .{result});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const vec_mult = try parseInput(allocator, input, true);

    const result = @reduce(.Add, vec_mult);
    std.debug.print("\nResult: {d}", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
