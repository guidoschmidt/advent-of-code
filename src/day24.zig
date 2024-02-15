const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const MIN: f64 = 200000000000000;
const MAX: f64 = 400000000000000;

fn matchingSign(num1: f64, num2: f64) bool {
    if (num1 > 0 and num2 < 0)
        return false;
    if (num1 < 0 and num2 > 0)
        return false;
    return true;
}

pub fn calculateIntersection(x1: f64, y1: f64, x2: f64, y2: f64,
                             x3: f64, y3: f64, x4: f64, y4: f64) @Vector(3, f64) {
    var intersection = @Vector(3, f64){ 0, 0, 0 };
    const x_numer = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1-x2) * (x3 * y4 - y3 * x4);
    const y_numer = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4);
    const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

    intersection[0] = x_numer / denom;
    intersection[1] = y_numer / denom;
    return intersection;
}

const Hailstone = struct {
    position: @Vector(3, f64),
    velocity: @Vector(3, f64),

    pub fn format(self: Hailstone,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("× [{d: >3}, {d: >3}, {d: >3}] → [{d: >3}, {d: >3}, {d: >3}]",
                         .{ self.position[0], self.position[1], self.position[2],
                            self.velocity[0], self.velocity[1], self.velocity[2] });
    }

    pub fn findEnd(self: Hailstone, range: f64) @Vector(3, f64) {
        return self.position + self.velocity * @Vector(3, f64) { range, range, range };
    }
};

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenizeAny(u8, input, "\n");

    var hailstones = std.ArrayList(Hailstone).init(gpa);

    while(row_it.next()) |row| {
        var pos_vel_it = std.mem.split(u8, row, "@");
        var pos_str = pos_vel_it.next().?;
        var vel_str = pos_vel_it.next().?;

        var pos = std.mem.splitSequence(u8, pos_str, ", ");
        var vel = std.mem.splitSequence(u8, vel_str, ", ");

        var position: [3]f64 = undefined;
        var velocity: [3]f64 = undefined;
        var i: usize = 0;
        while(i < 3) : (i += 1) {
            var p_str =  std.mem.trim(u8, pos.next().?, " ");
            var p_num = try std.fmt.parseFloat(f64, p_str);
            var v_str =  std.mem.trim(u8, vel.next().?, " ");
            var v_num = try std.fmt.parseFloat(f64, v_str);
            position[i] = p_num;
            velocity[i] = v_num;
        }
        try hailstones.append(Hailstone {
            .position = position,
            .velocity = velocity,
        });
    }

    // const hailestone_a = Hailstone {
    //     .position = @Vector(3, f64){19, 13, 30},
    //     .velocity = @Vector(3, f64){-2, 1, -2},
    // };
    // const hailestone_b = Hailstone {
    //     .position = @Vector(3, f64){20, 19, 15},
    //     .velocity = @Vector(3, f64){1, -5, -3},
    // };

    // const end_a_min = hailestone_a.findEnd(-1);
    // const end_a_max = hailestone_a.findEnd(1);

    // const end_b_min = hailestone_b.findEnd(-1);
    // const end_b_max = hailestone_b.findEnd(1);

    // const x1 = end_a_min[0];
    // const y1 = end_a_min[1];
    // const x2 = end_a_max[0];
    // const y2 = end_a_max[1];
    // const x3 = end_b_min[0];
    // const y3 = end_b_min[1];
    // const x4 = end_b_max[0];
    // const y4 = end_b_max[1];

    // const intersect = calculateIntersection(x1, y1, x2, y2, x3, y3, x4, y4);
    // std.debug.print("\n{any}", .{ hailestone_a });
    // std.debug.print("\n{any}", .{ hailestone_b });
    // std.debug.print("\n--- {d:.1}, {d:.1}", .{ intersect[0], intersect[1] });

    // const rel_a = intersect - hailestone_a.position;
    // const a_in_past_x = !matchingSign(rel_a[0], hailestone_a.velocity[0]);
    // const a_in_past_y = !matchingSign(rel_a[1], hailestone_a.velocity[1]);
    // std.debug.print("\nA in past?: {any} : {any}", .{ a_in_past_x, a_in_past_y });

    // const rel_b = intersect - hailestone_b.position;
    // const b_in_past_x = !matchingSign(rel_b[0], hailestone_b.velocity[0]);
    // const b_in_past_y = !matchingSign(rel_b[1], hailestone_b.velocity[1]);
    // std.debug.print("\nB in past?: {any} : {any}", .{ b_in_past_x, b_in_past_y });

    const inf = std.math.inf(f64);
    var intersections: u16  = 0;
    for(0..hailstones.items.len) |idx_a| {
        var hailstone_a = hailstones.items[idx_a];
        var end_min_a = hailstone_a.findEnd(MIN);
        var end_max_a = hailstone_a.findEnd(MAX);
        for(idx_a..hailstones.items.len) |idx_b| {
            if (idx_a == idx_b) continue;

            var hailstone_b = hailstones.items[idx_b];
            var end_min_b = hailstone_b.findEnd(MIN);
            var end_max_b = hailstone_b.findEnd(MAX);

            const x1 = end_min_a[0];
            const y1 = end_min_a[1];

            const x2 = end_max_a[0];
            const y2 = end_max_a[1];
            std.debug.print("\n{any}", .{ hailstone_a });
            std.debug.print("\n    [{d}, {d}] --- [{d}, {d}]", .{ x1, y1, x2, y2 });

            const x3 = end_min_b[0];
            const y3 = end_min_b[1];
            const x4 = end_max_b[0];
            const y4 = end_max_b[1];
            std.debug.print("\n{any}", .{ hailstone_b });
            std.debug.print("\n    [{d}, {d}] --- [{d}, {d}]", .{ x3, y3, x4, y4 });

            var intersect = calculateIntersection(x1, y1, x2, y2, x3, y3, x4, y4);

            const rel_a = intersect - hailstone_a.position;
            const a_in_past_x = !matchingSign(rel_a[0], hailstone_a.velocity[0]);
            const a_in_past_y = !matchingSign(rel_a[1], hailstone_a.velocity[1]);

            const rel_b = intersect - hailstone_b.position;
            const b_in_past_x = !matchingSign(rel_b[0], hailstone_b.velocity[0]);
            const b_in_past_y = !matchingSign(rel_b[1], hailstone_b.velocity[1]);

            if (intersect[0] != inf and intersect[1] != inf and
                intersect[0] != -inf and intersect[1] != -inf and
                intersect[0] > MIN and intersect[0] < MAX and
                intersect[1] > MIN and intersect[1] < MAX and
                !(a_in_past_x or a_in_past_y) and
                !(b_in_past_x or b_in_past_y)) {
                intersections += 1;
                std.debug.print("\nINTERSECTION [{d:.3}, {d:.3}]", .{ intersect[0], intersect[1] });
            }

            std.debug.print("\n\n", .{});
        }
    }
    std.debug.print("\n\nFound {d} intersections\n", .{ intersections });
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = gpa;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runPart(gpa, 24, .PUZZLE, part1);
}

test "Basic line intersection" {
    var line_a_start = @Vector(2, f64){0, 0};
    var line_a_end = @Vector(2, f64){1, 1};

    var line_b_start = @Vector(2, f64){1, 0};
    var line_b_end = @Vector(2, f64){0, 1};

    var res = calculateIntersection(line_a_start[0], line_a_start[1], line_a_end[0], line_a_end[1],
                                    line_b_start[0], line_b_start[1], line_b_end[0], line_b_end[1]);
    std.debug.print("\n{d:.2}, {d:.2}", .{ res[0], res[1] });
}
