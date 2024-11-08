const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

const Path = struct {
    id: u16,
    heat_loss: u32,
    last_x: usize,
    last_y: usize,
    dir_x: @Vector(2, usize),
    step_counter: usize,

    pub fn step(self: *Path, map: *[][]u8) void {
        self.heat_loss += map.*[self.last_y][self.last_x];
        std.debug.print("\nHeat loss: {d}", .{ self.heat_loss });

        // Left
        const v_l = map.*[self.last_y][self.last_x -| 1];
        _ = v_l;

        // Right
        const v_r = map.*[self.last_y][self.last_x +| 1];
        _ = v_r;

        // Forward
        const v_f = map.*[self.last_y +| 1][self.last_x];
        _ = v_f;
    }
};

fn printMap(map: *[][]u8) void {
    std.debug.print("\n\n", .{});
    for(0..map.len) |x| {
        const row = map.*[x];
        for(0..row.len) |y| {
            std.debug.print("{d}", .{ map.*[x][y] });
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

    const path_list = std.ArrayList(Path).init(gpa);
    _ = path_list;

    var start_path = Path{
        .last_x = 0,
        .last_y = 0,
        .dir_x = @Vector(2, usize){0, 0},
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

    try aoc.runPart(gpa, 2023, 17, .EXAMPLE, part1);
    try aoc.runPart(gpa, 2023, 17, .EXAMPLE, part2);
}
