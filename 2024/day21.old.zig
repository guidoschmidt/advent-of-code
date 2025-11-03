const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");
const VectorSet = @import("./VectorSet.zig").VectorSet;

const DAY: u8 = 21;
const Allocator = std.mem.Allocator;
const log = std.log;

const Cmd = enum(u21) {
    UP = '↑',
    LEFT = '←',
    DOWN = '↓',
    RIGHT = '→',
    ENTER = 'A',
};

pub fn utf8Encode(c: u21, a: Allocator) ![]u8 {
    const buffer: []u8 = try a.alloc(u8, try std.unicode.utf8CodepointSequenceLength(c));
    _ = try std.unicode.utf8Encode(c, buffer);
    return buffer;
}

const NumericKeypadButton = enum(u21) {
    var buffer: [4]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    N7 = '7',
    N8 = '8',
    N9 = '9',
    N4 = '4',
    N5 = '5',
    N6 = '6',
    N1 = '1',
    N2 = '2',
    N3 = '3',
    N0 = '0',
    A = 'A',
    EMPTY = ' ',

    pub fn format(self: NumericKeypadButton, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        const str = try utf8Encode(@intFromEnum(self), allocator);
        defer allocator.free(str);
        try writer.print(" {s} ", .{str});
    }
};
const DirectionalKeypadButton = enum(u21) {
    var buffer: [4]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    A = 'A',
    UP = '↑',
    LEFT = '←',
    DOWN = '↓',
    RIGHT = '→',
    EMPTY = ' ',

    pub fn format(self: DirectionalKeypadButton, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        const str = try utf8Encode(@intFromEnum(self), allocator);
        defer allocator.free(str);
        try writer.print(" {s} ", .{str});
    }
};

fn Keypad(comptime T: type) type {
    return struct {
        buffer: [][3]T = undefined,
        pos: @Vector(2, usize) = undefined,

        pub fn init(a: Allocator) !Keypad(T) {
            return switch (T) {
                DirectionalKeypadButton => {
                    const instance = Keypad(T){
                        .buffer = try a.alloc([3]DirectionalKeypadButton, 2),
                        .pos = .{ 2, 0 },
                    };
                    instance.buffer[0] = [3]DirectionalKeypadButton{ .EMPTY, .UP, .A };
                    instance.buffer[1] = [3]DirectionalKeypadButton{ .LEFT, .DOWN, .RIGHT };
                    return instance;
                },
                NumericKeypadButton => {
                    const instance = Keypad(T){
                        .buffer = try a.alloc([3]NumericKeypadButton, 4),
                        .pos = .{ 2, 3 },
                    };
                    instance.buffer[0] = [3]NumericKeypadButton{ .N7, .N8, .N9 };
                    instance.buffer[1] = [3]NumericKeypadButton{ .N4, .N5, .N6 };
                    instance.buffer[2] = [3]NumericKeypadButton{ .N1, .N2, .N3 };
                    instance.buffer[3] = [3]NumericKeypadButton{ .EMPTY, .N0, .A };
                    return instance;
                },
                else => unreachable,
            };
        }

        pub fn shortestPath(self: *Keypad(T), allocator: Allocator, target: T) ![]DirectionalKeypadButton {
            var dst_pos: @Vector(2, usize) = .{ 0, 0 };
            for (0..self.buffer.len) |y| {
                for (0..self.buffer[0].len) |x| {
                    if (self.buffer[y][x] == target) {
                        dst_pos = .{ x, y };
                        break;
                    }
                }
            }

            const dirs = [_]@Vector(4, isize){
                .{ -1, 0, 0, '←' },
                .{ 1, 0, 0, '→' },
                .{ 0, -1, 0, '↑' },
                .{ 0, 1, 0, '↓' },
            };

            var q = std.array_list.Managed(@Vector(4, isize)).init(allocator);
            var visited = VectorSet(4, isize).init(allocator);
            try q.append(.{ @intCast(self.pos[0]), @intCast(self.pos[1]), 0, ' ' });
            var path = std.array_list.Managed(@Vector(4, isize)).init(allocator);
            var result = std.array_list.Managed(DirectionalKeypadButton).init(allocator);

            while (q.items.len > 0) {
                std.mem.sort(@Vector(4, isize), q.items, {}, comptime struct {
                    pub fn f(_: void, a: @Vector(4, isize), b: @Vector(4, isize)) bool {
                        return a[2] > b[2];
                    }
                }.f);

                const current_pos = q.pop();
                try path.append(current_pos);
                const current_val = self.buffer[@intCast(current_pos[1])][@intCast(current_pos[0])];
                try visited.insert(current_pos);

                if (current_val == target) {
                    for (1..path.items.len) |i| {
                        const step = path.items[i];
                        const dir: DirectionalKeypadButton = @enumFromInt(step[3]);
                        self.pos[0] = @intCast(step[0]);
                        self.pos[1] = @intCast(step[1]);
                        // log.info("{s}", .{self});
                        // aoc.blockAskForNext();
                        try result.append(dir);
                    }
                    break;
                }

                for (dirs) |dir| {
                    var neighbour = current_pos + dir;
                    if (neighbour[0] < 0 or
                        neighbour[1] < 0 or
                        neighbour[0] >= self.buffer[0].len or
                        neighbour[1] >= self.buffer.len or
                        @reduce(.And, neighbour == current_pos) or
                        visited.contains(neighbour) or
                        self.buffer[@intCast(neighbour[1])][@intCast(neighbour[0])] == .EMPTY)
                        continue;
                    const x2 = std.math.pow(isize, neighbour[0] - @as(isize, @intCast(dst_pos[0])), 2);
                    const y2 = std.math.pow(isize, neighbour[1] - @as(isize, @intCast(dst_pos[1])), 2);
                    const distance: f32 = @sqrt(@as(f32, @floatFromInt(x2 + y2)));
                    neighbour[2] = @intFromFloat(distance);
                    neighbour[3] = dir[3];
                    try q.insert(0, neighbour);
                }
            }

            try result.append(@enumFromInt('A'));
            return result.items;
        }

        pub fn format(self: Keypad(T), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            for (0..self.buffer.len) |y| {
                try writer.print("\n", .{});
                const row = self.buffer[y];
                for (0..row.len) |x| {
                    const v = self.buffer[y][x];
                    if (self.pos[0] == x and self.pos[1] == y) {
                        try writer.print("{s}{any}{s}", .{ t.green, v, t.clear });
                        continue;
                    }
                    try writer.print("{any}", .{v});
                }
            }
        }
    };
}

const KeypadController = struct {
    codes: [][]const u8 = undefined,
    numeric: Keypad(NumericKeypadButton) = undefined,
    directional: Keypad(DirectionalKeypadButton) = undefined,

    pub fn init(a: Allocator, codes: [][]const u8) !KeypadController {
        var instance = KeypadController{};
        instance.codes = codes;
        instance.numeric = try Keypad(NumericKeypadButton).init(a);
        instance.directional = try Keypad(DirectionalKeypadButton).init(a);
        return instance;
    }

    pub fn findButtonSequence(self: *KeypadController, allocator: Allocator, code: []const u8) !void {
        log.info("{any}", .{self.directional});
        log.info("{any}", .{self.numeric});

        var sequence = std.array_list.Managed(DirectionalKeypadButton).init(allocator);

        for (code) |code_char| {
            // sequence.clearAndFree();

            log.info("Need to press button {c}", .{code_char});
            const result = try self.numeric.shortestPath(allocator, @enumFromInt(code_char));
            for (result) |a| {
                const a_result = try self.directional.shortestPath(allocator, a);
                for (a_result) |b| {
                    try sequence.append(b);
                    // const b_result = try self.directional.shortestPath(allocator, b);
                    // for (b_result) |c| {
                    // const c_result = try self.directional.shortestPath(allocator, c);
                    // for (c_result) |d| try sequence.append(d);
                    // }
                }
            }
        }
        std.debug.print("\nSEQUENCE\n", .{});
        for (sequence.items) |s| {
            std.debug.print("{s}", .{s});
        }
        std.debug.print("\n", .{});
        std.debug.print("{d}", .{sequence.items.len});
    }

    pub fn enterCodes(self: *KeypadController, allocator: Allocator) !void {
        for (self.codes) |c| {
            try self.findButtonSequence(allocator, c);
            break;
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !KeypadController {
    const trimmed = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, trimmed, "\n");
    var codes = std.array_list.Managed([]const u8).init(allocator);
    while (it.next()) |row| {
        try codes.append(row);
    }

    return KeypadController.init(allocator, codes.items);
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var keypad_ctrl = try parseInput(allocator, input);

    try keypad_ctrl.enterCodes(allocator);
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
