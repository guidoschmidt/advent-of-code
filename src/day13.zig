// Source: https://github.com/qsantos/advent-of-code/blob/master/2023/day12/src/main.rs#L6-L46
const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Pattern = struct {
    data: []u8 = undefined,
    width: usize = undefined,
    height: usize = undefined,
    row_matrix: [][]u8 = undefined,
    col_matrix: [][]u8 = undefined,

    pub fn init(self: *Pattern, allocator: Allocator, input: []const u8) !void {
        var row_it = std.mem.tokenize(u8, input, "\n");
        self.width = row_it.peek().?.len;

        while (row_it.next()) |_| {
            self.height += 1;
        }

        self.data = try allocator.alloc(u8, input.len);
        _ = std.mem.replace(u8, input, "\n", "", self.data);

        try self.allocateMatrix(allocator);
    }

    pub fn allocateMatrix(self: *Pattern, allocator: Allocator) !void {
        self.row_matrix = try allocator.alloc([]u8, self.height);
        for (0..self.height) |r| {
            self.row_matrix[r] = try allocator.alloc(u8, self.width);
            for(0..self.width) |c| {
                self.row_matrix[r][c] = self.data[r * self.width + c];
            }
        }

        self.col_matrix = try allocator.alloc([]u8, self.width);
        for (0..self.width) |c| {
            self.col_matrix[c] = try allocator.alloc(u8, self.height);
            for(0..self.height) |r| {
                self.col_matrix[c][r] = self.data[r * self.width + c];
            }
        }
    }

    pub fn findReflection(self: *Pattern) !usize {
        std.debug.print("\n{any}", .{ self.data });

        var result: usize = 0;

        std.debug.print("\n{s}------------------------{s}", .{ common.red, common.clear });
        std.debug.print("\nPattern Size: {d} x {d}", .{ self.width, self.height });

        std.debug.print("\n\n--- ROWS\n", .{});
        for(0..self.row_matrix.len) |r| {
            std.debug.print("\n{d: >2}  {s}  {d: >2}", .{ r + 1, self.row_matrix[r], r + 1 });
        }
        std.debug.print("\n", .{});
        // Rows
        var equal_count_rows: usize = 0;
        var reflection_rows: [2]?usize = [2]?usize{ null, null };
        outer: for(0..self.row_matrix.len - 1) |r| {
            var row_a = self.row_matrix[r];
            var row_b = self.row_matrix[r + 1];
            const equal = std.mem.eql(u8, row_a, row_b);
            if (equal) {
                equal_count_rows += 1;
                reflection_rows[0] = r + 1;
                reflection_rows[1] = r + 2;
                // After finding a reflection, check the other row pairs for equality, to
                // see if they match up...
                var others_equal = true;
                validation: for (1..self.row_matrix.len) |r_b| {
                    std.debug.print("\n[{d} {d}] --> {d} | {d}", .{ r, r + 1, r -| r_b, r + 1 + r_b });
                    if (r + r_b + 1 >= self.row_matrix.len or @as(i16, @intCast(r)) - @as(i16, @intCast(r_b)) < 0) {
                        break :validation;
                    }
                    row_a = self.row_matrix[r -| r_b];
                    row_b = self.row_matrix[r + 1 + r_b];
                    others_equal = others_equal and std.mem.eql(u8, row_a, row_b);
                    std.debug.print("\n{s} | {s} --> {any}", .{ row_a, row_b, others_equal });
                }
                // If any of the row pairs don't match, it's not a proper reflection!
                if (!others_equal) {
                    reflection_rows[0] = null;
                    reflection_rows[1] = null;
                    equal_count_rows = 0;
                }
                if (others_equal) {
                    reflection_rows[0] = r + 1;
                    reflection_rows[1] = r + 2;
                    const diff = @as(i16, @intCast(reflection_rows[0].?)) - @as(i16, @intCast(reflection_rows[1].?));
                    equal_count_rows = @intCast(try std.math.absInt(diff));
                    std.debug.print("\n[{?}, {?}], {d} ", .{ reflection_rows[0], reflection_rows[1], diff });
                    if (equal_count_rows == 1) break :outer;
                }
            }
            std.debug.print("\n{s}[{d: >2}] {s}   :   {s}[{d: >2}] {s} ⟶ {any}", .{common.blue, r + 1 , row_a, common.red, r + 2, row_b, equal });
        }
        std.debug.print("\n{s}", .{ common.clear });
        std.debug.print("\n{s}---- ??? Potential Reflection on row [{?}, {?}]", .{ common.clear, reflection_rows[0], reflection_rows[1] });
        if (equal_count_rows == 1) {
            std.debug.print("\n{s}---- ✓ Reflection on row [{?}, {?}]", .{ common.clear, reflection_rows[0], reflection_rows[1] });
            result += (reflection_rows[0] orelse 0) * 100;
        }

        std.debug.print("\n--- COLUMNS\n", .{});
        for(0..self.col_matrix.len) |c| {
            std.debug.print("\n{d: >2}  {s}  {d: >2}", .{ c + 1, self.col_matrix[c], c + 1 });
        }
        // Columns
        // std.debug.print("\n{s}", .{ common.yellow });
        var equal_count_cols: usize = 0;
        var reflection_cols: [2]?usize = [2]?usize{ null, null };
        outer: for(0..self.col_matrix.len - 1) |c| {
            // std.debug.print("\n[{d} {d}]", .{c, self.col_matrix.len - c});
            var col_a = self.col_matrix[c];
            var col_b = self.col_matrix[c + 1];
            const equal = std.mem.eql(u8, col_a, col_b);
            if (equal) {
                equal_count_cols += 1;
                reflection_cols[0] = c + 1;
                reflection_cols[1] = c + 2;
                // After finding a reflection, check the other column pairs for equality, to
                // see if they match up...
                var others_equal = true;
                validation: for (1..self.col_matrix.len) |c_b| {
                    std.debug.print("\n[{d} {d}] --> {d} | {d}", .{ c, c + 1, c -| c_b, c + 1 + c_b });
                    if (c + c_b + 1 >= self.col_matrix.len or @as(i16, @intCast(c)) - @as(i16, @intCast(c_b)) < 0) {
                        break :validation;
                    }
                    col_a = self.col_matrix[c -| c_b];
                    col_b = self.col_matrix[c + 1 + c_b];
                    others_equal = others_equal and std.mem.eql(u8, col_a, col_b);
                    std.debug.print("\n{s} | {s} --> {any}", .{ col_a, col_b, others_equal });
                }
                // If any of the column pairs don't match, it's not a proper reflection!
                if (!others_equal) {
                    reflection_cols[0] = null;
                    reflection_cols[1] = null;
                    equal_count_cols = 0;
                }
                if (others_equal) {
                    reflection_cols[0] = c + 1;
                    reflection_cols[1] = c + 2;
                    const diff = @as(i16, @intCast(reflection_cols[0].?)) - @as(i16, @intCast(reflection_cols[1].?));
                    equal_count_cols = @intCast(try std.math.absInt(diff));
                    if (equal_count_cols == 1) break :outer;
                }
            }
            std.debug.print("\n{s}[{d: >2}] {s}      {s}[{d: >2}] {s} ⟶ {any}", .{common.blue, c + 1, col_a, common.red, c + 2, col_b, equal });
        }
        std.debug.print("\n{s}---- ??? Potential Reflection on col [{?}, {?}]", .{ common.clear, reflection_cols[0], reflection_cols[1] });
        if (equal_count_cols == 1) {
            std.debug.print("\n---- ✓ {s}Reflection on col [{?}, {?}]", .{ common.clear, reflection_cols[0], reflection_cols[1] });
            result += reflection_cols[0] orelse 0;
        }
        return result;
    }

    pub fn deinit(self: *Pattern, allocator: Allocator) void {
        allocator.free(self.data);
        for (0..self.width) |x| {
            allocator.free(self.col_matrix[x]);
        }
        allocator.free(self.col_matrix);
        for (0..self.height) |y| {
            allocator.free(self.row_matrix[y]);
        }
        allocator.free(self.row_matrix);
    }
};

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.split(u8, input, "\n");
    var pattern_list = std.ArrayList(Pattern).init(allocator);

    var current_pattern_data = std.ArrayList(u8).init(allocator);
    while(row_it.next()) |row| {
        if (row.len == 0) {
            // @TODO next pattern
            var pattern = Pattern {};
            try pattern.init(allocator, current_pattern_data.items);
            try pattern_list.append(pattern);
            current_pattern_data.clearAndFree();
            continue;
        }
        try current_pattern_data.appendSlice(row);
        try current_pattern_data.append('\n');
    }

    var result: usize = 0;
    std.debug.print("\n{d} Pattern", .{ pattern_list.items.len });
    for(pattern_list.items) |*pattern| {
        result += try pattern.findReflection();

        // step: {
        //     const in = std.io.getStdIn();
        //     var buf = std.io.bufferedReader(in.reader());
        //     var r = buf.reader();
        //     std.debug.print("\n\nNext?... ", .{});
        //     var msg_buf: [4096]u8 = undefined;
        //     _ = try r.readUntilDelimiterOrEof(&msg_buf, '\n');
        //     break :step;
        //  }


        defer pattern.deinit(allocator);
    }
    std.debug.print("\n\nResult: {d}", .{ result });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try common.runDay(allocator, 13, .PUZZLE, part1, part2);
}
