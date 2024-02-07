const std = @import("std");
const common = @import("common.zig");
const ppm = @import("ppm.zig");

const Allocator = std.mem.Allocator;

const Dir = enum {
    U,
    D,
    L,
    R
};


const Command = struct {
    dir: Dir,
    meters: u8,
    color_code: []const u8,
};

fn printMap(map: *[][]u8) void {
    std.debug.print("\n\n", .{});
    for(0..map.len) |x| {
        const row = map.*[x];
        for(0..row.len) |y| {
            std.debug.print("{c}{s}", .{ map.*[x][y], common.clear });
        }
        std.debug.print("\n", .{});
    }
}

fn floodFill(gpa: Allocator, map: *[][]u8, start: [2]usize) !void {
    var stack = std.ArrayList([2]usize).init(gpa);
    defer stack.deinit();
    try stack.append(start);
    while(stack.items.len > 0) {
        var next = stack.pop();
        var x = next[0];
        var y = next[1];
        if (map.*[y][x] == '.') {
            map.*[y][x] = '#';
            try stack.append([2]usize{x + 1, y});
            try stack.append([2]usize{x - 1, y});
            try stack.append([2]usize{x, y + 1});
            try stack.append([2]usize{x, y - 1});
        }
    }
}

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");
    var command_list = std.ArrayList(Command).init(gpa);
    while(row_it.next()) |row| {
        var part_it = std.mem.tokenize(u8, row, " ");
        var dir: Dir = switch(part_it.next().?[0]) {
            'U' => Dir.U,
            'D' => Dir.D,
            'L' => Dir.L,
            'R' => Dir.R,
            else => unreachable,
        };
        var meters = try std.fmt.parseInt(u8, part_it.next().?, 10);
        var color_code_str = part_it.next().?;
        var color_code = color_code_str[1..color_code_str.len - 1];
        try command_list.append(Command{
            .dir = dir,
            .meters = meters,
            .color_code = color_code
        });
    }
    std.mem.reverse(Command, command_list.items);
    const command_count: u16 = @intCast(command_list.items.len);

    var max_width: usize = 0;
    var max_height: usize = 0;
    for(command_list.items) |cmd| {
        if (cmd.dir == Dir.R)
            max_width += cmd.meters;
        if (cmd.dir == Dir.D)
            max_height += cmd.meters;
    }
    max_width *= 2;
    max_height *= 2;
    std.debug.print("\n{d} x {d}", .{ max_width, max_height });

    var map: [][]u8 = try gpa.alloc([]u8, max_width);
    for(0..map.len) |x| {
        map[x] = try gpa.alloc(u8, max_height);
        for(0..map[x].len) |y| {
            map[x][y] = '.';
        }
    }

    var pos: [2]usize = [_]usize{ max_width / 2, max_height / 2 };
    var center_pos: [2]usize = [_]usize{ max_width / 2, max_height / 2 };
    while (command_list.items.len > 0) {
        const next_cmd = command_list.pop();
        std.debug.print("\n{any}", .{ next_cmd });
        center_pos[0] += pos[0];
        center_pos[1] += pos[1];
        switch (next_cmd.dir) {
            Dir.U => {
                for(0..next_cmd.meters) |_| {
                    pos[1] = pos[1] -| 1;
                    map[pos[1]][pos[0]] = '#';
                }
            },
            Dir.D => {
                for(0..next_cmd.meters) |_| {
                    pos[1] += 1;
                    map[pos[1]][pos[0]] = '#';
                }
            },
            Dir.R => {
                for(0..next_cmd.meters) |_| {
                    pos[0] += 1;
                    map[pos[1]][pos[0]] = '#';
                }
            },
            Dir.L => {
                for(0..next_cmd.meters) |_| {
                    pos[0] = pos[0] -| 1;
                    map[pos[1]][pos[0]] = '#';
                }
            },
        }
    }
    center_pos[0] /= command_count;
    center_pos[1] /= command_count;
    // map[center_pos[1]][center_pos[0]] = 'X';
    try floodFill(gpa, &map, center_pos);

    try ppm.init("out.ppm", max_width, max_height);
    try ppm.write(&map);

    var squares: usize = 0;
    for(0..map.len) |x| {
        for(0..map[x].len) |y| {
            if (map[x][y] == '#') squares += 1; 
        }
    }
    std.debug.print("\n\nResult: {d}\n", .{ squares });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runDay(gpa, 18, .PUZZLE, part1, part2);
}
