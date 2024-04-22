const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Path = struct {
    id: u16,
    heat_loss: u32,
    last_x: usize,
    last_y: usize,
    dir_x: @Vector(2, usize),
    step_counter: usize,

    pub fn step(self: *Path, map: *[][]u8) void {
        self.heat_loss += map.*[self.y][self.x];
        std.debug.print("\nHeat loss: {d}", .{ self.heat_loss });

        // Left
        var v_l = map.*[self.y][self.x -| 1];

        // Right
        var v_r = map.*[self.y][self.x +| 1];

        // Forward
        var v_f = map.*[self.y +| 1][self.x];
    }
};

fn printMap(map: *[][]u8) void {
    std.debug.print("\n\n", .{});
    for(0..map.len) |x| {
        const row = map.*[x];
        for(0..row.len) |y| {
            std.debug.print("{d}{s}", .{ map.*[x][y], common.clear });
        }
        std.debug.print("\n", .{});
    }
}

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    const cleaned_input = try std.mem.replaceOwned(u8, gpa, input, "\n", "");
    var row_it = std.mem.tokenize(u8, input, "\n");

    const width = row_it.peek().?.len;
    var height: usize = 0;
    while(row_it.next()) |_| height += 1;

    std.debug.print("\nMap size {d} x {d}", .{ width, height });

    var map = try gpa.alloc([]u8, width);
    for(0..map.len) |x| {
        map[x] = try gpa.alloc(u8, height);
        for (0..map[x].len) |y| {
            const digit = try std.fmt.charToDigit(cleaned_input[x * height + y], 10);
            map[x][y] = digit;
        }
    }

    printMap(&map);

    var path_list = std.ArrayList(Path).init(gpa);
    _ = path_list;

    var start_path = Path{
        .x = 0,
        .y = 0,
        .heat_loss = 0,
        .id = 0,
        .step_counter = 0
    };
    start_path.step(&map);
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runDay(gpa, 17, .EXAMPLE, part1, part2);
}
