const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const SplitAt = struct {
    x: i16,
    y: i16,
};

const Trace = struct {
    x: i16,
    y: i16,
    dx: i16,
    dy: i16,
};

fn printMap(map: *[][]u8, trace: ?Trace) void {
    std.debug.print("\n", .{});
    for(0..map.len) |x| {
        const row = map.*[x];
        std.debug.print("{d: >3}    ", .{ x });
        for(0..row.len) |y| {
            if (trace != null and trace.?.y == x and trace.?.x == y) {
                std.debug.print("{s}", .{ common.red });
            }
            std.debug.print("{c}{s}", .{ map.*[x][y], common.clear });
        }
        std.debug.print("\n", .{});
    }
}

fn animateMap(map: *[][]u8, trace: ?Trace) void {
    for(0..map.len) |x| {
        const row = map.*[x];
        for(0..row.len) |y| {
            std.debug.print("\x1B[{d};{d}H", .{ x, y });
            if (trace != null and trace.?.y == x and trace.?.x == y) {
                std.debug.print("{s}", .{ common.red });
            }
            std.debug.print("{c}{s}", .{ map.*[x][y], common.clear });
        }
    }
    std.time.sleep(1000 * 1000 * 30);
}

fn countEnergized(map: *[][]u8) u32 {
    var count: u32 = 0;
    for(0..map.len) |x| {
        const row = map.*[x];
        for(0..row.len) |y| {
            if (row[y] != '.') {
                count += 1;
            }
        }
    }
    return count;
}

fn traceBeam(gpa: std.mem.Allocator, map: *[][]u8, beam_map: *[][]u8, beam_split_map: *[][]u2, trace: Trace) ![]Trace {
    // printMap(beam_map, trace);
    // animateMap(beam_map, trace);
    var trace_list = std.ArrayList(Trace).init(gpa);
    if (trace.x >= 0 and
        trace.y >= 0 and
        trace.y <= map.len and
        trace.x <= map.*[0].len) {
        const map_val = map.*[@intCast(trace.y)][@intCast(trace.x)];
        if (map_val == '.') {
            if (trace.dx > 0)
                beam_map.*[@intCast(trace.y)][@intCast(trace.x)] = '>';
            if (trace.dy > 0)
                beam_map.*[@intCast(trace.y)][@intCast(trace.x)] = 'v';
            if (trace.dx < 0)
                beam_map.*[@intCast(trace.y)][@intCast(trace.x)] = '<';
            if (trace.dy < 0)
                beam_map.*[@intCast(trace.y)][@intCast(trace.x)] = '^';
        } else {
            beam_map.*[@intCast(trace.y)][@intCast(trace.x)] = map.*[@intCast(trace.y)][@intCast(trace.x)];
        }
    }

    const next_x: i16 = trace.x +| trace.dx;
    const next_y: i16 = trace.y +| trace.dy;
    // std.debug.print("\nNext: {d}, {d}", .{ next_x, next_y });
    if (next_y < 0 or next_x < 0 or next_y >= map.len or next_x >= map.*[0].len) {
        return trace_list.items;
    }
    const next = map.*[@intCast(next_y)][@intCast(next_x)];
    // std.debug.print("-- {c}", .{ next });
    var next_dx: i16 = trace.dx;
    var next_dy: i16 = trace.dy;
    switch(next) {
        '.' => try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = next_dx, .dy = next_dy }),
        '|' => {
            if (beam_split_map.*[@intCast(next_y)][@intCast(next_x)] > 0) return trace_list.items;
            if (trace.dx == -1 or trace.dx == 1) {
                // Split beam
                beam_split_map.*[@intCast(next_y)][@intCast(next_x)] = 1;
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = 0, .dy = -1 });
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = 0, .dy =  1 });
            } else {
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = next_dx, .dy = next_dy });
            }
        },
        '-' => {
            if (trace.dy == -1 or trace.dy == 1) {
                if (beam_split_map.*[@intCast(next_y)][@intCast(next_x)] > 0) return trace_list.items;
                // Split beam
                beam_split_map.*[@intCast(next_y)][@intCast(next_x)] = 1;
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = -1, .dy = 0 });
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx =  1, .dy = 0 });
            } else {
                try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = next_dx, .dy = next_dy });
            }
        },
        '/' => {
            // From left
            if (trace.dx == 1 and trace.dy == 0) {
                next_dx = 0;
                next_dy = -1;
            }
            // From top
            if (trace.dx == 0 and trace.dy == 1) {
                next_dx = -1;
                next_dy = 0;
            }
            // From right
            if (trace.dx == -1 and trace.dy == 0) {
                next_dx = 0;
                next_dy = 1;
            }
            // From bottom
            if (trace.dx == 0 and trace.dy == -1) {
                next_dx = 1;
                next_dy = 0;
            }
            try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = next_dx, .dy = next_dy });
        },
        '\\' => {
            // From left
            if (trace.dx == 1 and trace.dy == 0) {
                next_dx = 0;
                next_dy = 1;
            }
            // From top
            if (trace.dx == 0 and trace.dy == 1) {
                next_dx = 1;
                next_dy = 0;
            }
            // From right
            if (trace.dx == -1 and trace.dy == 0) {
                next_dx = 0;
                next_dy = -1;
            }
            // From bottom
            if (trace.dx == 0 and trace.dy == -1) {
                next_dx = -1;
                next_dy = 0;
            }
            try trace_list.append(Trace{.x = next_x, .y = next_y, .dx = next_dx, .dy = next_dy });
        },
        else => {},
    }
    return trace_list.items;
}

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    const cleaned_input = try std.mem.replaceOwned(u8, gpa, input, "\n", "");
    var row_it = std.mem.tokenize(u8, input, "\n");

    const width = row_it.peek().?.len;
    var height: usize = 0;
    while(row_it.next()) |_| height += 1;
    std.debug.print("\nMap size: {d} x {d}", .{ width, height });

    row_it.reset();

    var map = try gpa.alloc([]u8, width);
    var beam_map = try gpa.alloc([]u8, width);
    var beam_split_map = try gpa.alloc([]u2, width);
    for(0..map.len) |x| {
        map[x] = try gpa.alloc(u8, height);
        beam_map[x] = try gpa.alloc(u8, height);
        beam_split_map[x] = try gpa.alloc(u2, height);
        for(0..map[x].len) |y| {
            map[x][y] = cleaned_input[x * height + y];
            beam_map[x][y] = '.';
            beam_split_map[x][y] = 0;
        }
    }

    printMap(&map, null);

    var trace_list = std.ArrayList(Trace).init(gpa);
    try trace_list.append(Trace{.x = -1, .y = 0, .dx = 1, .dy = 0});
    while (trace_list.items.len > 0) {
        const next_trace = trace_list.pop();
        var new_traces = try traceBeam(gpa, &map, &beam_map, &beam_split_map, next_trace);
        // std.debug.print("\nNext Trace: {any}", .{ next_trace });
        // std.debug.print("\nNew traces: {d}", .{ new_traces.len });
        // common.blockAskForNext();
        for (new_traces) |new_trace| {
            try trace_list.append(new_trace);
        }
    }

    printMap(&beam_map, null);

    var result = countEnergized(&beam_map);
    std.debug.print("\n\n{d}\n", .{ result });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runDay(gpa, 16, .PUZZLE, part1, part2);
}
