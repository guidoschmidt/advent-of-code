// @TODO this needs heavy refactoring
// @TODO still has a bug which leads to 4 missing tiles

const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const INSIDE = 'l';
const OUTSIDE = 'r';

var dist_map: []i32 = undefined;
var row_it: std.mem.TokenIterator(u8, .any) = undefined;
var col_count: u32 = undefined;
var row_count: u32 = undefined;
var start: Pos = undefined;

const Pos = struct {
    x: i32,
    y: i32,
};

const Dir = enum {
    NORTH,
    EAST,
    SOUTH,
    WEST
};

fn isInside(pos: Pos, cols: u32, rows: u32) bool {
    _ = rows;
    const idx = @as(u32, @intCast(pos.y)) * cols + @as(u32, @intCast(pos.x));
    if (idx >= 0 and idx < dist_map.len) {
        return dist_map[@intCast(idx)] < 0;
    }
    return false;
}

fn tileToArrow(tile: u8) []const u8 {
    return switch(tile) {
        // vertical pipe connecting north and south
        '|' => "┃",
        // horizontal pipe connecting east and west
        '-' => "━",
        // 90-degree bend connecting north and east
        'L' => "┗",
        // 90-degree bend connecting north and west
        'J' => "┛",
        // 90-degree bend connecting south and west
        '7' => "┓",
        // 90-degree bend connecting south and east
        'F' => "┏",
        'S' => "\x1B[31m●\x1B[0m",
        'Q' => "\x1B[32m●\x1B[0m",
        INSIDE => "\x1B[33m●\x1B[0m",
        OUTSIDE => "\x1B[34m●\x1B[0m",
        else => "?"
    };
}

fn printArrowTile(tile: u8) void {
    std.debug.print("{s}", .{ tileToArrow(tile) }); 
}

fn printDefaultTile(tile: u8) void {
    std.debug.print("{c}", .{ tile }); 
}

fn animateMap(pipe_map: *[]u8, rows: u32, cols: u32, comptime print_fn: fn(u8) void) void {
    for(0..rows) |dy| {
        for(0..cols) |dx| {
            const idx = dy * cols + dx;
            const pipe_tile = pipe_map.*[idx];
            std.debug.print("\x1B[{d};{d}H", .{ dy, dx });
            print_fn(pipe_tile);
        }
    }
    std.time.sleep(1000 * 1000 * 16);
}

fn printMap(name: []const u8, map: *[]u8, rows: u32, cols: u32, comptime print_fn: fn(u8) void) void {
    std.debug.print("\n{s}:\n", .{ name });
    for(0..rows) |dy| {
        for(0..cols) |dx| {
            const idx = dy * cols + dx;
            const pipe_tile = map.*[idx];
            print_fn(pipe_tile);
        }
        std.debug.print("\n", .{});
    }
}

fn printDistMap(map: *[]i32, rows: u32, cols: u32) void {
    std.debug.print("\nDISTANCE MAP:\n", .{});
    for(0..rows) |dy| {
        for(0..cols) |dx| {
            const idx = dy * cols + dx;
            const dist_val = map.*[idx];
            switch (dist_val) {
                1 => std.debug.print("{s}", .{ "P" }),
                0 => std.debug.print("{c}", .{ ' ' }),
                7 => std.debug.print("{c}", .{ 'I' }),
                8 => std.debug.print("{c}", .{ 'O' }),
                9 => std.debug.print("{c}", .{ '_' }),
                else => {
                    if (dist_val < 0) {
                        std.debug.print("{c}", .{ '.' });
                    }
                }
            }
        }
        std.debug.print("\n", .{});
    }
}

fn findInsides(pos: Pos, direction: Dir, cols: u32, rows: u32, input_map: []const u8, pipe_map: *[]u8, inside_candidates: *std.ArrayList(Pos), outside_candidates: *std.ArrayList(Pos)) void {
    var next_position = pos;
    var next_dir = direction;

    loop: while(true) {

        // animateMap(pipe_map, rows, cols, printArrowTile);

        var next_pos = next_position;
        var current_dir = next_dir;

        switch (current_dir) {
            Dir.NORTH => next_pos.y -= 1,
            Dir.EAST => next_pos.x += 1,
            Dir.SOUTH => next_pos.y += 1,
            Dir.WEST => next_pos.x -= 1,
        }

        if (next_pos.x < 0 or next_pos.x > cols - 1 or next_pos.y < 0 or next_pos.y > rows - 1) continue;

        const pos_idx = next_pos.y * @as(i32, @intCast(cols)) + next_pos.x;
        if (input_map[@intCast(pos_idx)] != '.' and dist_map[@intCast(pos_idx)] < 0 ) {
            dist_map[@intCast(pos_idx)] = 1; //@intCast(next_step);
            pipe_map.*[@intCast(pos_idx)] = input_map[@intCast(pos_idx)];
        }

        // Find left position
        var left_pos = Pos { .x = next_pos.x, .y = next_pos.y };
        var right_pos = Pos { .x = next_pos.x, .y = next_pos.y };
        switch (current_dir) {
            Dir.NORTH => {
                left_pos.x -= 1;
                right_pos.x += 1;
            },
            Dir.EAST => {
                left_pos.y -= 1;
                right_pos.y += 1;
            },
            Dir.SOUTH => {
                left_pos.x += 1;
                right_pos.x -= 1;
            },
            Dir.WEST => {
                left_pos.y += 1;
                right_pos.y -= 1;
            },
        }
        if (left_pos.x >= 0 and left_pos.x < cols and left_pos.y >= 0 and left_pos.y < rows) {
            const left_pos_idx = left_pos.y * @as(i32, @intCast(cols)) + left_pos.x;
            if (dist_map[@intCast(left_pos_idx)] < 0) {
                pipe_map.*[@intCast(left_pos_idx)] = INSIDE;
                inside_candidates.append(left_pos) catch unreachable;
            }
        }
        if (right_pos.x >= 0 and right_pos.x < cols and right_pos.y >= 0 and right_pos.y < rows) {
            const right_pos_idx = right_pos.y * @as(i32, @intCast(cols)) + right_pos.x;
            if (dist_map[@intCast(right_pos_idx)] < 0) {
                pipe_map.*[@intCast(right_pos_idx)] = OUTSIDE;
                outside_candidates.append(right_pos) catch unreachable;
            }
        }
        if (input_map[@intCast(pos_idx)] == 'F') {
            var left_pos2 = Pos { .x = next_pos.x - 1, .y = next_pos.y };
            if (left_pos2.x >= 0 and left_pos2.x < cols and left_pos2.y >= 0 and left_pos2.y < rows) {
                const left_pos2_idx = left_pos2.y * @as(i32, @intCast(cols)) + left_pos2.x;
                if (dist_map[@intCast(left_pos2_idx)] < 0) {
                    // pipe_map.*[@intCast(left_pos2_idx)] = INSIDE;
                    // inside_candidates.append(left_pos2) catch unreachable;
                }
            }
            var left_diagonal_pos = Pos { .x = next_pos.x - 1, .y = next_pos.y - 1 };
            if (left_diagonal_pos.x >= 0 and left_diagonal_pos.x < cols and left_pos.y >= 0 and left_diagonal_pos.y < rows) {
                const left_diagonal_pos_idx = left_diagonal_pos.y * @as(i32, @intCast(cols)) + left_diagonal_pos.x;
                if (left_diagonal_pos_idx > 0 and left_diagonal_pos_idx < dist_map.len and dist_map[@intCast(left_diagonal_pos_idx)] < 0) {
                    pipe_map.*[@intCast(left_diagonal_pos_idx)] = INSIDE;
                    inside_candidates.append(left_diagonal_pos) catch unreachable;
                }
            }
        }
        if (input_map[@intCast(pos_idx)] == 'J') {
            var left_pos2 = Pos { .x = next_pos.x + 1, .y = next_pos.y - 1 };
            if (left_pos2.x >= 0 and left_pos2.x < cols and left_pos2.y >= 0 and left_pos2.y < rows) {
                const left_pos2_idx = left_pos2.y * @as(i32, @intCast(cols)) + left_pos2.x;
                if (dist_map[@intCast(left_pos2_idx)] < 0) {
                    pipe_map.*[@intCast(left_pos2_idx)] = INSIDE;
                    inside_candidates.append(left_pos2) catch unreachable;
                }
            }
            var left_diagonal_pos = Pos { .x = next_pos.x, .y = next_pos.y + 1 };
            if (left_diagonal_pos.x >= 0 and left_diagonal_pos.x < cols and left_pos.y >= 0 and left_diagonal_pos.y < rows) {
                const left_diagonal_pos_idx = left_diagonal_pos.y * @as(i32, @intCast(cols)) + left_diagonal_pos.x;
                if (dist_map[@intCast(left_diagonal_pos_idx)] < 0) {
                    pipe_map.*[@intCast(left_diagonal_pos_idx)] = INSIDE;
                    inside_candidates.append(left_diagonal_pos) catch unreachable;
                }
            }
        }
        if (input_map[@intCast(pos_idx)] == '7') {
            var left_pos2 = Pos { .x = next_pos.x + 1, .y = next_pos.y };
            if (left_pos2.x >= 0 and left_pos2.x < cols and left_pos2.y >= 0 and left_pos2.y < rows) {
                const left_pos2_idx = left_pos2.y * @as(i32, @intCast(cols)) + left_pos2.x;
                if (dist_map[@intCast(left_pos2_idx)] < 0) {
                    pipe_map.*[@intCast(left_pos2_idx)] = INSIDE;
                    inside_candidates.append(left_pos2) catch unreachable;
                }
            }
            var left_diagonal_pos = Pos { .x = next_pos.x + 1, .y = next_pos.y - 1 };
            if (left_diagonal_pos.x >= 0 and left_diagonal_pos.x < cols and left_pos.y >= 0 and left_diagonal_pos.y < rows) {
                const left_diagonal_pos_idx = left_diagonal_pos.y * @as(i32, @intCast(cols)) + left_diagonal_pos.x;
                if (left_diagonal_pos_idx > 0 and left_diagonal_pos_idx < dist_map.len and dist_map[@intCast(left_diagonal_pos_idx)] < 0) {
                    pipe_map.*[@intCast(left_diagonal_pos_idx)] = INSIDE;
                    inside_candidates.append(left_diagonal_pos) catch unreachable;
                }
            }
        }
        if (input_map[@intCast(pos_idx)] == 'L') {
            var left_pos2 = Pos { .x = next_pos.x - 1, .y = next_pos.y };
            if (left_pos2.x >= 0 and left_pos2.x < cols and left_pos2.y >= 0 and left_pos2.y < rows) {
                const left_pos2_idx = left_pos2.y * @as(i32, @intCast(cols)) + left_pos2.x;
                if (dist_map[@intCast(left_pos2_idx)] < 0) {
                    pipe_map.*[@intCast(left_pos2_idx)] = INSIDE;
                    inside_candidates.append(left_pos2) catch unreachable;
                }
            }
            var left_diagonal_pos = Pos { .x = next_pos.x - 1, .y = next_pos.y + 1 };
            if (left_diagonal_pos.x >= 0 and left_diagonal_pos.x < cols and left_pos.y >= 0 and left_diagonal_pos.y < rows) {
                const left_diagonal_pos_idx = left_diagonal_pos.y * @as(i32, @intCast(cols)) + left_diagonal_pos.x;
                if (dist_map[@intCast(left_diagonal_pos_idx)] < 0) {
                    pipe_map.*[@intCast(left_diagonal_pos_idx)] = INSIDE;
                    inside_candidates.append(left_diagonal_pos) catch unreachable;
                }
            }
        }

        // Proceed
        next_position = next_pos;
        next_dir = findNextDir(next_pos, cols, rows, input_map) orelse break :loop;
    }
}


fn follow(step: u32, pos: *[2]Pos, directions: []Dir, cols: u32, rows: u32, input_map: []const u8, pipe_map: *[]u8) void {
    var next_positions = pos;
    var next_dirs = directions;
    var next_step = step;
    loop: while (true) {
        // printPipeMap(pipe_map, row_count, col_count, printArrowTile);

        for (0..next_dirs.len) |i| {
            var next_pos = next_positions[i];
            var current_dir = next_dirs[i];

            switch (current_dir) {
                Dir.NORTH => next_pos.y -= 1,
                Dir.EAST => next_pos.x += 1,
                Dir.SOUTH => next_pos.y += 1,
                Dir.WEST => next_pos.x -= 1,
            }

            if (next_pos.x < 0 or next_pos.x > cols - 1 or next_pos.y < 0 or next_pos.y > rows - 1) continue;

            const pos_idx = next_pos.y * @as(i32, @intCast(cols)) + next_pos.x;
            if (input_map[@intCast(pos_idx)] != '.' and dist_map[@intCast(pos_idx)] < 0 ) {
                dist_map[@intCast(pos_idx)] = 1; //@intCast(next_step);
                pipe_map.*[@intCast(pos_idx)] = input_map[@intCast(pos_idx)];
            }

            next_positions[i] = next_pos;
            const next_dir = findNextDir(next_pos, cols, rows, input_map) orelse break :loop;
            next_dirs[i] = next_dir;
        }
        next_step+=1;
    }

    std.debug.print("\n\nResult{}\n", .{ next_step });
}

fn findNextDir(current_pos: Pos, cols: u32, rows: u32, pipe_map: []const u8) ?Dir {
    var next_dir: ?Dir = null;
    // std.debug.print("\nCURRENT POS: [{d} x {d}]", .{ current_pos.x, current_pos.y });
    const dirs = [4]Dir{ Dir.NORTH, Dir.EAST, Dir.SOUTH, Dir.WEST };
    for (dirs) |dir| {
        var test_pos = current_pos;
        switch(dir) {
            Dir.NORTH => test_pos.y -= 1,
            Dir.EAST => test_pos.x += 1,
            Dir.SOUTH => test_pos.y += 1,
            Dir.WEST => test_pos.x -= 1,
        }
        const current_pos_idx = current_pos.y * @as(i32, @intCast(cols)) + current_pos.x;
        const test_pos_idx = test_pos.y * @as(i32, @intCast(cols)) + test_pos.x;
        if (test_pos.x >= 0 and test_pos.y >= 0 and test_pos.x < cols and test_pos.y < rows and
            dist_map[@intCast(test_pos_idx)] < 0) {
            const current_tile = pipe_map[@intCast(current_pos_idx)];
            const next_tile = pipe_map[@intCast(test_pos_idx)];
            if (next_tile == '.') continue;
            // std.debug.print("\n      ??? {any} : {c} → {c}", .{ dir, current_tile, next_tile });
            switch(dir) {
                Dir.NORTH => {
                    // Think of it like:
                    // On which tile can we go into the given direction?
                    switch(current_tile) {
                        '|','J','L' => next_dir = Dir.NORTH,
                        else => {}
                    } 
                },
                Dir.EAST => {
                    switch(current_tile) {
                        'F','L','-' => next_dir = Dir.EAST,
                        else => {}
                    } 
                },
                Dir.SOUTH => {
                    switch(current_tile) {
                        '|','F','7' => next_dir = Dir.SOUTH,
                        else => {}
                    } 
                },
                Dir.WEST => {
                    switch(current_tile) {
                        '-', '7', 'J' => next_dir = Dir.WEST,
                        else => {}
                    } 
                }
            }
        }
    }
    // std.debug.print("\n   {any} ⟶  {any}", .{ current_dir, next_dir });
    return next_dir;

}

fn findStartDirections(pos: Pos, cols: u32, input_map: []const u8, pipe_map: *[]u8) std.ArrayList(Dir) {
    const pos_idx = pos.y * @as(i32, @intCast(cols)) + pos.x;
    if (input_map[@intCast(pos_idx)] != '.' and dist_map[@intCast(pos_idx)] < 0 ) {
        dist_map[@intCast(pos_idx)] = 1; //@intCast(step);
        pipe_map.*[@intCast(pos_idx)] = input_map[@intCast(pos_idx)];
    }

    var start_directions = std.ArrayList(Dir).init(allocator);
    inline for(std.meta.fields(Dir)) |d| {
        var test_pos = pos;
        var dir = @as(Dir, @enumFromInt(d.value));
        switch (dir) {
            Dir.NORTH => test_pos.y -= 1,
            Dir.EAST => test_pos.x += 1,
            Dir.SOUTH => test_pos.y += 1,
            Dir.WEST => test_pos.x -= 1,
        }

        const test_pos_idx = test_pos.y * @as(i32, @intCast(cols)) + test_pos.x;
        const tile = input_map[@intCast(test_pos_idx)];
        if (dir == Dir.NORTH and (tile == '|' or tile == '7' or tile == 'F')) {
            start_directions.append(dir) catch unreachable;
        }
        if (dir == Dir.SOUTH and (tile == '|' or tile == 'L' or tile == 'J')) {
            start_directions.append(dir) catch unreachable;
        }
        if (dir == Dir.EAST and (tile == '-' or tile == 'J' or tile == '7')) {
            start_directions.append(dir) catch unreachable;
        }
        if (dir == Dir.WEST and (tile == '-' or tile == 'F' or tile == 'L')) {
            start_directions.append(dir) catch unreachable;
        }
    }

    std.debug.print("\nFollow directions on start:", .{});
    for(start_directions.items) |follow_dir| {
        std.debug.print("\n→ {any}", .{ follow_dir });
    }
    std.debug.print("\n", .{});

    return start_directions ;
}

fn findStart(cols: u32, input_map: []u8, pipe_map: []u8)  void {
    var y: i32 = 0;
    start = Pos{.x=0, .y=0};
    while(row_it.next()) |row| : (y += 1) {
        // std.debug.print("\n{s}", .{ row });
        for(0..row.len) |x| {
            const idx = @as(u32, @intCast(y)) * cols + @as(u32, @intCast(x));
            const tile = row[x];
            input_map[idx] = tile;
            pipe_map[idx] = '.';
            if (row[x] == 'S') {
                pipe_map[idx] = 'S';
                dist_map[idx] = 1;
                start.x = @intCast(x);
                start.y = @intCast(y);
            }
        }
    }
}

fn part1(input: []const u8) void {
    row_it = std.mem.tokenize(u8, input, "\n\r");
    col_count = @intCast(row_it.peek().?.len);
    row_count = @as(u32, @intCast(row_it.buffer.len)) / (col_count + 1);

    dist_map = allocator.alloc(i32, col_count * row_count) catch unreachable;
    var pipe_map = allocator.alloc(u8, col_count * row_count) catch unreachable;
    var input_map = allocator.alloc(u8, col_count * row_count) catch unreachable;

    std.debug.print("\nMap size {d} x {d}", .{ row_count, col_count });

    findStart(col_count, input_map, pipe_map);
    std.debug.print("\n\nStart at [{d} x {d}]", .{ start.x, start.y });
    var step: u32 = 0;
    var start_directions = findStartDirections(start, col_count, input_map, &pipe_map);
    var start_positions = [2]Pos{ start, start };
    follow(step + 1, &start_positions, start_directions.items, col_count, row_count, input_map, &pipe_map);

    printMap("INPUT MAP", &input_map, row_count, col_count, printDefaultTile);
    printMap("PIPE MAP", &pipe_map, row_count, col_count, printArrowTile);
    printDistMap(&dist_map, row_count, col_count);
}

fn floodFill(candidates: *std.ArrayList(Pos), pipe_map: []u8, map_number: u8, map_char: u8) void {
    var q = std.ArrayList(Pos).init(allocator);
    q.appendSlice(candidates.items) catch unreachable;
    while(q.items.len > 0) {
        const elem = q.pop();
        // std.debug.print("\n{d} x {d}", .{ elem.x, elem.y });
        var is_inside = isInside(elem, col_count, row_count);
        if (is_inside) {
            const idx = @as(usize, @intCast(elem.y)) * col_count + @as(usize, @intCast(elem.x));
            dist_map[idx] = map_number;
            pipe_map[idx] = map_char;

            var right = Pos{.x = @intCast(@min(@as(u32, @intCast(elem.x + 1)), row_count + 1)), .y = elem.y };
            var bottom = Pos{.x = elem.x, .y = @intCast(@min(@as(u32, @intCast(elem.y + 1)), row_count - 1)) };
            var left = Pos{.x = @intCast(@max(@as(i32, @intCast(elem.x - 1)), 0)), .y = elem.y };
            var top = Pos{.x = elem.x, .y = @intCast(@max(@as(i32, @intCast(elem.y - 1)), 0)) };

            // var top_right = Pos{.x = @intCast(@min(@as(u32, @intCast(elem.x + 1)), row_count + 1)), .y = @intCast(@max(@as(i32, @intCast(elem.y - 1)), 0)) };
            // var top_left = Pos{.x = @intCast(@max(@as(i32, @intCast(elem.x - 1)), 0)), .y = @intCast(@max(@as(i32, @intCast(elem.y - 1)), 0)) };

            // var bottom_right = Pos{.x = @intCast(@min(@as(u32, @intCast(elem.x + 1)), row_count + 1)), .y = @intCast(@max(@as(u32, @intCast(elem.y + 1)), row_count - 1)) };
            // var bottom_left = Pos{.x = @intCast(@max(@as(i32, @intCast(elem.x - 1)), 0)), .y = @intCast(@max(@as(u32, @intCast(elem.y + 1)), row_count - 1)) };

            q.append(right) catch unreachable;
            q.append(bottom) catch unreachable;
            q.append(left) catch unreachable;
            q.append(top) catch unreachable;

            // q.append(top_right) catch unreachable;
            // q.append(top_left) catch unreachable;
            // q.append(bottom_right) catch unreachable;
            // q.append(bottom_left) catch unreachable;
        }
    }
}

fn part2(input: []const u8) void {
    row_it = std.mem.tokenize(u8, input, "\n\r");
    col_count = @intCast(row_it.peek().?.len);
    row_count = @as(u32, @intCast(row_it.buffer.len)) / (col_count + 1);

    dist_map = allocator.alloc(i32, col_count * row_count) catch unreachable;
    var pipe_map = allocator.alloc(u8, col_count * row_count) catch unreachable;
    var input_map = allocator.alloc(u8, col_count * row_count) catch unreachable;

    std.debug.print("\nMap size {d} x {d}", .{ row_count, col_count });

    findStart(col_count, input_map, pipe_map);
    std.debug.print("\n\nStart at [{d} x {d}]", .{ start.x, start.y });
    var start_directions = findStartDirections(start, col_count, input_map, &pipe_map);
    var start_position = start;

    var inside_candidates = std.ArrayList(Pos).init(allocator);
    var outside_candidates = std.ArrayList(Pos).init(allocator);
    findInsides(start_position, start_directions.items[0], col_count, row_count, input_map, &pipe_map, &inside_candidates, &outside_candidates);

    floodFill(&outside_candidates, pipe_map, 7, INSIDE);
    floodFill(&inside_candidates, pipe_map, 8, OUTSIDE);

    printMap("INPUT MAP", &input_map, row_count, col_count, printDefaultTile);
    printMap("PIPE MAP", &pipe_map, row_count, col_count, printArrowTile);
    printDistMap(&dist_map, row_count, col_count);

    var missing_candidates = std.ArrayList(Pos).init(allocator);
    for(0..row_count) |y| {
        for(0..col_count) |x| {
            const idx = y * @as(u32, @intCast(col_count)) + x;
            if (dist_map[@intCast(idx)] < 0)
                missing_candidates.append(Pos{.x = @intCast(x), .y = @intCast(y)}) catch unreachable;
        }     
    }


    var count_inside: u32 = 0;
    for(0..dist_map.len) |i| {
        if (dist_map[i] == 7)
            count_inside += 1;
    }

    printMap("\nPIPE MAP", &pipe_map, row_count, col_count, printArrowTile);
    std.debug.print("\nResult: {d} + {d}", .{ count_inside, missing_candidates.items.len });
}

pub fn main() !void {
    try common.runDay(allocator, 10, .PUZZLE, part1, part2);
}
