const std = @import("std");
const common = @import("common.zig");
const ppm = @import("ppm.zig");
const svg = @import("svg.zig");

const Allocator = std.mem.Allocator;

const Dir = enum {
    U,
    D,
    L,
    R
};


const Command = struct {
    dir: Dir,
    meters: u32,
};

fn determinant(comptime T: type, a: T, b: T, c: T, d: T) T {
    return a * d - b * c;
}

fn shoeLace(corners: *[][2]i128) !i128 {
    var sum: i128 = 0;
    for (0..corners.len-1) |i| {
        const p0 = corners.*[i];
        // const i_next = try std.math.mod(usize, i + 1, corners.len);
        const i_next = i + 1;
        const p1 = corners.*[i_next];
        // sum += p1[0] * p2[1] - p2[0] * p1[1];
        sum += (p0[1] + p1[1]) * (p0[0] - p1[0]);
    }
    return @divExact(sum, 2);
}

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
        var meters = try std.fmt.parseInt(u16, part_it.next().?, 10);
        try command_list.append(Command{
            .dir = dir,
            .meters = meters,
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

    try ppm.init("out.pgm", max_width, max_height);
    try ppm.write(&map);

    var squares: usize = 0;
    for(0..map.len) |x| {
        for(0..map[x].len) |y| {
            if (map[x][y] == '#') squares += 1; 
        }
    }
    std.debug.print("\n\nResult: {d}\n", .{ squares });
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");
    var command_list = std.ArrayList(Command).init(gpa);
    while(row_it.next()) |row| {
        var part_it = std.mem.tokenize(u8, row, " ");
        _ = part_it.next();
        _ = part_it.next();
        var color_code_str = part_it.next().?;
        var color_code = color_code_str[1..color_code_str.len - 1];
        const meters_str = color_code[1..color_code.len - 1];
        const meters = try std.fmt.parseInt(u32, meters_str, 16);
        const dir_str = color_code[color_code.len - 1];
        const dir_num = try std.fmt.charToDigit(dir_str, 10);
        const dir = switch(dir_num) {
            0 => Dir.R,
            1 => Dir.D,
            2 => Dir.L,
            3 => Dir.U,
            else => unreachable,
        };
        try command_list.append(Command{
            .dir = dir,
            .meters = meters,
        });
    }
    std.mem.reverse(Command, command_list.items);

    var max_width: i128 = 0;
    var max_height: i128 = 0;
    for(command_list.items) |cmd| {
        if (cmd.dir == Dir.R)
            max_width += cmd.meters;
        if (cmd.dir == Dir.D)
            max_height += cmd.meters;
    }
    std.debug.print("\n{d} x {d}", .{ max_width, max_height });

    var pos: [2]i128 = [_]i128{ 0, 0 };
    var min: [2]i128 = [_]i128{ @intCast(max_width), @intCast(max_height) };
    var max: [2]i128 = [_]i128{ @intCast(-max_width), @intCast(-max_height) };
    var corners = std.ArrayList([2]i128).init(gpa);
    var outline_sum: i128 = 0;
    while (command_list.items.len > 0) {
        const next_cmd = command_list.pop();
        std.debug.print("\n{any}", .{ next_cmd });
        outline_sum += next_cmd.meters;
        // for (0..next_cmd.meters) |_|
        //     outline_sum += 1;
        try corners.append(pos);
        switch (next_cmd.dir) {
            Dir.U => {
                pos[1] -= next_cmd.meters;
                if (pos[1] < min[1])
                    min[1] = pos[1];
                if (pos[1] > max[1])
                    max[1] = pos[1];
            },
            Dir.D => {
                pos[1] += next_cmd.meters;
                if (pos[1] < min[1])
                    min[1] = pos[1];
                if (pos[1] > max[1])
                    max[1] = pos[1];
            },
            Dir.R => {
                pos[0] += next_cmd.meters;
                if (pos[0] < min[0])
                    min[0] = pos[0];
                if (pos[0] > max[0])
                    max[0] = pos[0];
            },
            Dir.L => {
                pos[0] -= next_cmd.meters;
                if (pos[0] < min[0])
                    min[0] = pos[0];
                if (pos[0] > max[0])
                    max[0] = pos[0];
            }
        }
    }
    std.debug.print("\nBBox min: [{d}, {d}], max: [{d}, {d}]", .{ min[0], min[1], max[0], max[1] });
    const vp_width = max[0] - min[0];
    const vp_height = max[1] - min[1];
    std.debug.print("\nViewport [{d}, {d}]", .{ vp_width, vp_height });

    const scaler = 1000;
    try svg.init("map.svg",
                 @intCast(@divFloor(vp_width, scaler)),
                 @intCast(@divFloor(vp_height, scaler)),
                 @intCast(@divFloor(min[0], scaler)),
                 @intCast(@divFloor(min[1], scaler)),
                 @intCast(@divFloor(max[0], scaler)),
                 @intCast(@divFloor(max[1], scaler)));
    try svg.startPolygon();
    for(0..corners.items.len) |i| {
        const p = corners.items[i];
        try svg.addPolygonPoint(@intCast(@divFloor(p[0] - min[0], scaler)),
                                @intCast(@divFloor(p[1] - min[1], scaler)));
    }
    try svg.endPolygon();
    try svg.close();

    std.debug.print("\n# Corner points {d}", .{ corners.items.len });

    var shoe_lace_sum = try shoeLace(&corners.items) + @divExact(outline_sum, 2) + 1;

    std.debug.print("\nOutline sum: {d: >20}", .{ outline_sum });
    std.debug.print("\nShoe Lace:   {d: >20}", .{ shoe_lace_sum  });
    // std.debug.print("\nSummed:      {d: >20}", .{ shoe_lace_sum + outline_sum });
    std.debug.print("\nExample:     {d: >20}", .{ 952408144115 });
    std.debug.print("\n--- OFF:     {d: >20}", .{ 952408144115 - shoe_lace_sum });
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runPart(gpa, 18, .PUZZLE, part1);
    try common.runPart(gpa, 18, .PUZZLE, part2);
}
