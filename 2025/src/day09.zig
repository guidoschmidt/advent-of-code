const std = @import("std");
const aoc = @import("aoc");
const t = @import("libs").term;
const svg = @import("libs").svg;
const Map = @import("libs").Map;

const DAY: u5 = 9;

const Allocator = std.mem.Allocator;
const log = std.log;

fn calcArea(x0: u64, x1: u64, y0: u64, y1: u64) u64 {
    const vec_a: u64 = @abs(@as(i64, @intCast(x0)) - @as(i64, @intCast(x1))) + 1;
    const vec_b: u64 = @abs(@as(i64, @intCast(y0)) - @as(i64, @intCast(y1))) + 1;
    return vec_a * vec_b;
}

fn distance(a: @Vector(2, u64), b: @Vector(2, u64)) f64 {
    const vec: @Vector(2, f64) = @as(@Vector(2, f64), @floatFromInt(a)) - @as(@Vector(2, f64), @floatFromInt(b));
    return @sqrt(@exp2(vec))[0];
}

fn findLeftMostLowest(list: *std.array_list.Managed(@Vector(2, u64))) @Vector(2, u64) {
    std.debug.assert(list.items.len > 2);
    var result = list.items[0];
    for (list.items) |p| {
        if (p[0] < result[0]) {
            result = p;
            if (p[1] < result[1]) {
                result = p;
            }
        }
    }
    return result;
}

/// Cast a ray from point p to the right
/// Count how many times it intersects the path
/// count is odd => inside, count is even => outside
fn insidePath(path: *std.array_list.Managed(@Vector(2, u64)), p: @Vector(2, u64)) bool {
    var inside = false;
    for (0..path.items.len) |i| {
        const a = path.items[i];
        const b = path.items[(i + 1) % path.items.len];

        // Convert to signed integers for comparison
        const ax = @as(i64, @intCast(a[0]));
        const ay = @as(i64, @intCast(a[1]));
        const bx = @as(i64, @intCast(b[0]));
        const by = @as(i64, @intCast(b[1]));
        const px = @as(i64, @intCast(p[0]));
        const py = @as(i64, @intCast(p[1]));

        // Check if edge crosses the horizontal ray from point p to the right
        // Edge must straddle the horizontal line at py
        if ((ay >= py) != (by >= py)) {
            // Calculate x-coordinate of intersection point
            // Using: x = ax + (py - ay) * (bx - ax) / (by - ay)
            const slope_num = (py - ay) * (bx - ax);
            const slope_den = by - ay;
            const intersect_x = ax + @divTrunc(slope_num, slope_den);

            // If intersection is to the right of point p, toggle inside
            if (px + 1 < intersect_x) {
                inside = !inside;
            }
        }
    }

    return inside;
}

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-09");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    var it: std.Io.Reader = .fixed(input);
    var tiles: std.array_list.Managed(@Vector(2, u64)) = .init(allocator);
    defer tiles.deinit();

    var last_area: u64 = 0;
    while (try it.takeDelimiter('\n')) |line| {
        if (std.mem.indexOf(u8, line, ",")) |sep| {
            const x = try std.fmt.parseInt(u64, line[0..sep], 10);
            const y = try std.fmt.parseInt(u64, line[sep + 1 ..], 10);
            for (tiles.items) |_| {
                const area = calcArea(x, t[0], y, t[1]);
                last_area = @max(area, last_area);
            }
            try tiles.append(.{ x, y });
        }
    }
    std.debug.print("Largest area: {d}\n", .{last_area});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-09");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    var it: std.Io.Reader = .fixed(input);
    var tiles: std.array_list.Managed(@Vector(2, u64)) = .init(allocator);
    defer tiles.deinit();

    var largest: @Vector(2, usize) = .{ 0, 0 };
    while (try it.takeDelimiter('\n')) |line| {
        if (std.mem.indexOf(u8, line, ",")) |sep| {
            const x = try std.fmt.parseInt(u64, line[0..sep], 10);
            const y = try std.fmt.parseInt(u64, line[sep + 1 ..], 10);
            // map.set(x, y, '#');
            if (x > largest[0]) {
                largest[0] = x;
            }
            if (y > largest[1]) {
                largest[1] = y;
            }
            try tiles.append(.{ x, y });
        }
    }

    std.debug.print("{d} x {d}\n", .{ largest[0], largest[1] });

    try svg.init(
        "2025-day09-part2.svg",
        largest[0],
        largest[1],
        0,
        largest[0],
        0,
        largest[1],
    );

    try svg.startPolygon();
    for (tiles.items) |tile| {
        try svg.addPolygonPoint(tile[0], tile[1]);
    }
    try svg.endPolygon("green");

    var path: std.array_list.Managed(@Vector(2, u64)) = .init(allocator);
    defer path.deinit();

    const start = findLeftMostLowest(&tiles);
    try path.append(start);

    // const map: Map = try .initEmpty(allocator, 14, 8, '.');
    // defer map.deinit();

    std.debug.print("Start: {d}\n", .{start});
    // map.set(start[0], start[1], 'S');

    const tile_count = tiles.items.len;
    var current = start;
    var idx: u64 = 1;
    while (true) {
        if (idx >= tile_count) break;
        var closest_idx: usize = 0;
        var closest = tiles.items[closest_idx];
        var d: f64 = 100.0;
        for (1..tiles.items.len) |i| {
            const tile = tiles.items[i];
            if (tile[0] == current[0] and tile[1] == current[1]) continue;
            if (current[0] != tile[0] and current[1] != tile[1]) continue;
            const closest_d = distance(current, tile);
            if (closest_d < d) {
                d = closest_d;
                closest = tile;
                closest_idx = i;
            }
        }
        // map.set(closest[0], closest[1], idx + '0');
        idx += 1;
        current = closest;
        try path.append(tiles.swapRemove(closest_idx));
    }

    // std.debug.print("Path:\n{any}\n", .{path.items});
    // for (path.items) |p| {
    //     std.debug.print("{any}\n", .{p});
    // }

    // for (0..path.items.len) |p| {
    //     const s = path.items[@mod(p, path.items.len)];
    //     const n = path.items[@mod(p + 1, path.items.len)];
    //     const x_from = @min(s[0], n[0]);
    //     const x_to = @max(s[0], n[0]);
    //     const y_from = @min(s[1], n[1]);
    //     const y_to = @max(s[1], n[1]);
    //     if (x_from == x_to) {
    //         for (y_from + 1..y_to) |y| {
    //             // map.set(x_from, y, 'x');
    //         }
    //     }
    //     if (y_from == y_to) {
    //         std.debug.print("{d} -- {d}\n", .{ x_from, x_to });
    //         for (x_from + 1..x_to) |x| {
    //             // map.set(x, y_from, 'x');
    //         }
    //     }
    // }

    // const test_points = [_]@Vector(2, u64){
    //     .{ 4, 4 },
    //     .{ 1, 1 },
    //     .{ 5, 7 },
    //     .{ 2, 5 },
    //     .{ 2, 1 },
    // };
    // for (test_points) |p| {
    //     const orig = map.get(p[0], p[1]);
    //     map.set(p[0], p[1], '?');
    //     const is_inside = insidePath(&path, p);
    //     std.debug.print("Is Inside? --> {any}\n", .{is_inside});
    //     std.debug.print("{f}\n", .{map});
    //     map.set(p[0], p[1], orig);
    // }

    var largest_area: u64 = 0;
    var a: @Vector(2, u64) = .{ 0, 0 };
    var b: @Vector(2, u64) = .{ 0, 0 };
    for (0..path.items.len) |i| {
        const p = path.items[i];
        outer: for (0..path.items.len) |j| {
            const q = path.items[j];
            if (p[0] == q[0] and p[1] == q[1]) continue;
            const area = calcArea(p[0], q[0], p[1], q[1]);
            const opposite_a_inside = insidePath(&path, .{ p[0], q[1] });
            const opposite_b_inside = insidePath(&path, .{ q[0], p[1] });
            // const p_orig = map.get(p[0], p[1]);
            // const q_orig = map.get(q[0], q[1]);
            // const u_orig = map.get(p[0], q[1]);
            // const v_orig = map.get(q[0], p[1]);
            // map.set(p[0], p[1], 'O');
            // map.set(q[0], q[1], 'O');
            // map.set(p[0], q[1], 'O');
            // map.set(q[0], p[1], 'O');
            // std.debug.print("Area: {d} [{d} -- {d}] - Outside: {any}, {any}?\n{f}\n", .{
            //     area,
            //     i,
            //     j,
            //     opposite_a_inside,
            //     opposite_b_inside,
            //     map,
            // });
            // map.set(p[0], p[1], p_orig);
            // map.set(q[0], q[1], q_orig);
            // map.set(p[0], q[1], u_orig);
            // map.set(q[0], p[1], v_orig);
            if (opposite_a_inside and opposite_b_inside and area > largest_area) {
                var all_inside = true;
                if (p[1] < q[1]) {
                    for (p[1]..q[1]) |y| {
                        const inside = insidePath(&path, .{ p[0], y });
                        all_inside = all_inside and inside;
                        if (!all_inside) continue :outer;
                    }
                }
                if (q[1] < p[1]) {
                    for (q[1]..p[1]) |y| {
                        const inside = insidePath(&path, .{ p[0], y });
                        all_inside = all_inside and inside;
                        if (!all_inside) continue :outer;
                    }
                }
                if (all_inside) {
                    largest_area = area;
                    a = p;
                    b = q;
                }
            }
        }
    }
    try svg.startPolygon();
    try svg.addPolygonPoint(a[0], a[1]);
    try svg.addPolygonPoint(a[0], b[1]);
    try svg.addPolygonPoint(b[0], b[1]);
    try svg.addPolygonPoint(b[0], a[1]);
    try svg.endPolygon("red");

    try svg.close();

    std.debug.print("Area: {d}\n", .{largest_area});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}

test "simple test" {
    var a: @Vector(2, u32) = .{ 7, 1 };
    var b: @Vector(2, u32) = .{ 11, 7 };
    try std.testing.expect(calcArea(a[0], b[0], a[1], b[1]) == 35);
    try std.testing.expect(calcArea(b[0], a[0], b[1], a[1]) == 35);

    a = .{ 7, 3 };
    b = .{ 2, 3 };
    try std.testing.expect(calcArea(a[0], b[0], a[1], b[1]) == 6);
    try std.testing.expect(calcArea(b[0], a[0], b[1], a[1]) == 6);

    a = .{ 2, 5 };
    b = .{ 11, 1 };
    try std.testing.expect(calcArea(a[0], b[0], a[1], b[1]) == 50);
    try std.testing.expect(calcArea(b[0], a[0], b[1], a[1]) == 50);
}
