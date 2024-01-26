// Helped a lot:
// https://www.reddit.com/r/adventofcode/comments/18gqqbh/2023_day_12_part_1_solved_in_under_three_minutes/
const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const SpringGroup = struct {
    springs: []const u8,
    count: u8,
};

pub fn unfold(springs: []const u8, numeric: []const usize) SpringRecord {
    var unfolded_springs = allocator.alloc(u8, springs.len * 5) catch unreachable;
    for (0..unfolded_springs.len) |idx| {
        const mod_idx = std.math.mod(usize, idx, springs.len) catch unreachable;
        unfolded_springs[idx] = springs[mod_idx];
    }
    var unfolded_numeric = allocator.alloc(usize, numeric.len * 5) catch unreachable;
    for (0..unfolded_numeric.len) |idx| {
        const mod_idx = std.math.mod(usize, idx, numeric.len) catch unreachable;
        unfolded_numeric[idx] = numeric[mod_idx];
    }
    std.debug.print("\n{s} → {s}", .{ springs, unfolded_springs });
    std.debug.print("\n{any} → {any}", .{ numeric, unfolded_numeric });
    return SpringRecord {
        .springs = unfolded_springs,
        .numeric = unfolded_numeric,
    };
}

const PermutationError = error {
    NoMorePermutation,
};

const SpringsConfig = struct {
    idx: usize,
    configuration: []const u8,
};

const SpringRecord  = struct {
    springs: []const u8 = undefined,
    numeric: []const usize = undefined,
    variables: std.ArrayList(usize) =  std.ArrayList(usize).init(allocator),

    fn printSprings(self: *SpringRecord, springs: []const u8) void {
        for(0..springs.len) |s| {
            const needle = [_]usize{ s };
            if (std.mem.containsAtLeast(usize, self.variables.items, 1, &needle)) {
                std.debug.print("\x1B[31m{c}\x1B[0m", .{ springs[s] });
                continue;
            }
            std.debug.print("{c}", .{ springs[s] });
        }
    }

    pub fn findVariables(self: *SpringRecord) void {
        for(0..self.springs.len) |i| {
            if (self.springs[i] == '?') {
                self.variables.append(i) catch unreachable;
            }
        }
    }

    // @TODO refactor to day12.zig
    pub fn bruteForce(self: *SpringRecord) u32 {
        self.findVariables();
        // std.debug.print("\n", .{});
        // self.printSprings(self.springs);
        // std.debug.print("\n{any}", .{ self.variables.items });
      
        var working_combinations: u32 = 0;
        var configurations = std.ArrayList(SpringsConfig).init(allocator);

        var test_config_a = allocator.dupe(u8, self.springs) catch unreachable;
        test_config_a[self.variables.items[0]] = '#';
        configurations.append(SpringsConfig{
            .idx = 0,
            .configuration = test_config_a
        }) catch unreachable;
        var test_config_b = allocator.dupe(u8, self.springs) catch unreachable;
        test_config_b[self.variables.items[0]] = '.';
        configurations.append(SpringsConfig{
            .idx = 0,
            .configuration = test_config_b
        }) catch unreachable;

        while(configurations.items.len > 0) {
            var last_test_config = configurations.pop();
            const contains_variable = std.mem.containsAtLeast(u8, last_test_config.configuration, 1, "?");
            if (contains_variable) {
                const test_springs_a = allocator.dupe(u8, last_test_config.configuration) catch unreachable;
                test_springs_a[self.variables.items[last_test_config.idx + 1]] = '#';
                configurations.append(SpringsConfig{
                    .configuration = test_springs_a,
                    .idx = last_test_config.idx + 1,
                }) catch unreachable;

                const test_springs_b = allocator.dupe(u8, last_test_config.configuration) catch unreachable;
                test_springs_b[self.variables.items[last_test_config.idx + 1]] = '.';
                configurations.append(SpringsConfig{
                    .configuration = test_springs_b,
                    .idx = last_test_config.idx + 1,
                }) catch unreachable;
            }
            else {
                // std.debug.print("\n", .{});
                // self.printSprings(last_test_config.configuration);
                // std.debug.print("\n{any}", .{ self.numeric });
                if (self.testCriteria(last_test_config.configuration)) {
                    // std.debug.print("✓", .{});
                    working_combinations += 1;
                    // already_tested.insert(last_test_config.configuration) catch unreachable;
                }
            }
        }

        return working_combinations;
    }

    pub fn testCriteria(self: *SpringRecord, springs: []const u8) bool {
        if (self.springs.len != springs.len) return false;

        for(0..springs.len) |idx| {
            if (self.springs[idx] == '.' or self.springs[idx] == '#') {
                if (springs[idx] != self.springs[idx]) {
                    return false;
                }
            }
        }

        var split_it = std.mem.tokenize(u8, springs, ".");
        var group_counts = std.ArrayList(usize).init(allocator);
        while(split_it.next()) |split| {
            group_counts.append(@intCast(split.len)) catch unreachable;
        }
        const is_valid = std.mem.eql(usize, group_counts.items, self.numeric);
        return is_valid;
    }

    pub fn format(self: SpringRecord,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        for(0..self.springs.len) |s| {
            const needle = [_]usize{ s };
            if (std.mem.containsAtLeast(usize, self.variables.items, 1, &needle)) {
                try writer.print("\x1B[31m{c}\x1B[0m", .{ self.springs[s] });
                continue;
            }
            try writer.print("{c}", .{ self.springs[s] });
        }
        try writer.print(" — {any}", .{ self.numeric });
    }
};

fn part1(input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var records = std.ArrayList(SpringRecord).init(allocator);

    var row_num: u32 = 0;
    while(row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, " ");
        const springs = entry_it.next().?;
        const numeric_str = entry_it.next().?;

        var num_it = std.mem.tokenize(u8, numeric_str, ",");
        var numeric = std.ArrayList(usize).init(allocator);
        while(num_it.next()) |v| {
            const n = std.fmt.parseInt(usize, v, 10) catch unreachable;
            numeric.append(n) catch unreachable;
        }
        // std.debug.print("\n{d}: {any}", .{ row_num, numeric.items });
        
        const spring_record = SpringRecord{
            .springs = springs,
            .numeric = numeric.items,
        };
        records.append(spring_record) catch unreachable;
        row_num += 1;
    }

    var sum: u32 = 0;
    for(0..records.items.len) |i| {
        const working_combinations = records.items[i].bruteForce();
        std.debug.print("\n- {d} → \x1B[36m{d}\x1B[0m", .{ i, working_combinations });
        sum += working_combinations;
    }

    std.debug.print("\n\nResult: {d}\n", .{ sum });
}

fn part2(input: []const u8) anyerror!void {
    _ = input;
}

pub fn main() !void {
    try common.runDay(allocator, 12, .PUZZLE, part1, part2);
}
