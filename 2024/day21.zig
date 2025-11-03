// https://www.redditmedia.com/r/adventofcode/comments/1hj2odw/2024_day_21_solutions/
const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 21;
const Allocator = std.mem.Allocator;
const log = std.log;

const KeypadController = struct {
    allocator: Allocator,
    current: u8 = 'A',
    numeric_position_map: std.AutoHashMap(u8, @Vector(2, usize)) = undefined,
    position_map: std.AutoHashMap(u8, @Vector(2, usize)) = undefined,

    const numeric = [][]const u8{ "789", "456", "123", " 0A" };
    const directional = [][]const u8{ " ^A", "<v>" };

    pub fn init(self: *KeypadController) !void {
        self.position_map = std.AutoHashMap(u8, @Vector(2, usize)).init(self.allocator);
        try self.position_map.put('7', .{ 0, 0 });
        try self.position_map.put('8', .{ 1, 0 });
        try self.position_map.put('9', .{ 2, 0 });
        try self.position_map.put('4', .{ 0, 1 });
        try self.position_map.put('5', .{ 1, 1 });
        try self.position_map.put('6', .{ 2, 1 });
        try self.position_map.put('1', .{ 0, 2 });
        try self.position_map.put('2', .{ 1, 2 });
        try self.position_map.put('3', .{ 2, 2 });
        try self.position_map.put(' ', .{ 0, 3 });
        try self.position_map.put('0', .{ 1, 3 });
        try self.position_map.put('A', .{ 2, 3 });
    }

    pub fn doorSequence(self: *KeypadController, allocator: Allocator, next: u8) ![]const u8 {
        const dirs = ">^<v";
        var sequence = std.array_list.Managed(u8).init(allocator);

        // Early return
        if (self.current == next) return "A";

        const pos_next = self.position_map.get(next).?;
        const pos_current = self.position_map.get(self.current).?;
        const distance: @Vector(2, isize) =
            @as(@Vector(2, isize), @intCast(pos_next)) -
            @as(@Vector(2, isize), @intCast(pos_current));

        for (dirs) |dir| {
            switch (dir) {
                '<' => {
                    if (distance[0] < 0)
                        for (0..@abs(distance[0])) |_| try sequence.append(dir);
                },
                '>' => {
                    if (distance[0] > 0)
                        for (0..@abs(distance[0])) |_| try sequence.append(dir);
                },
                'v' => {
                    if (distance[1] > 0)
                        for (0..@abs(distance[1])) |_| try sequence.append(dir);
                },
                '^' => {
                    if (distance[1] < 0)
                        for (0..@abs(distance[1])) |_| try sequence.append(dir);
                },
                else => unreachable,
            }
        }

        try sequence.append('A');
        self.current = next;
        return sequence.items;
    }

    pub fn keypadSequenceCost(self: *KeypadController) !usize {
        const sequence = std.array_list.Managed(u8).init(self.allocator);
        _ = sequence;
    }

    pub fn cost(self: *KeypadController, sequence: []const u8) !usize {
        _ = self;
        _ = sequence;
    }

    pub fn complexity(self: *KeypadController, code: []const u8) !usize {
        var sequence = std.array_list.Managed(u8).init(self.allocator);

        var code_with_start: [5]u8 = undefined;
        code_with_start[0] = 'A';
        @memcpy(code_with_start[1..].ptr, code);
        for (code_with_start) |char| {
            const seq = try self.doorSequence(self.allocator, char);
            try sequence.appendSlice(seq);
        }
        log.info("{s}", .{sequence.items});

        return 0;
    }
};

fn parseInput(allocator: Allocator, input: []const u8) ![][]const u8 {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, trimmed, "\n");
    var codes = std.array_list.Managed([]const u8).init(allocator);
    while (it.next()) |row| {
        try codes.append(row);
    }
    return codes.items;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const codes = try parseInput(allocator, input);
    var keypad_ctrl = KeypadController{
        .allocator = allocator,
    };
    try keypad_ctrl.init();
    for (codes) |code| {
        log.info("\nCODE: {s}", .{code});
        _ = try keypad_ctrl.complexity(code);
    }
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
