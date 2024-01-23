const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const SpringGroup = struct {
    springs: []const u8,
    count: u8,
};

fn factorial(v: u32) u32 {
    if (v == 1) return v;
    return v * factorial(v - 1);
}


fn combinations(k: u32, n: u32) u32 {
    const t = n + k - 1;
    const u = k;
    return factorial(t) / (factorial(u) * factorial(t - u));
}

const PermutationError = error {
    NoMorePermutation,
};

const SpringRecord  = struct {
    springs: []const u8 = undefined,
    numeric: []const u8 = undefined,
    variables: std.ArrayList(usize) =  std.ArrayList(usize).init(allocator),
    num_of_possibilities: u8 = undefined,

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

    pub fn nextPerm(self: *SpringRecord, arr: []u8) ![]u8 {
        _ = self;
        var i = arr.len - 1;
        while(i > 0 and arr[i - 1] >= arr[i]) {
            i -= 1;
        }
        if (i <= 0) {
            return PermutationError.NoMorePermutation;
        }
        var j = arr.len - 1;
        while(arr[j] <= arr[i - 1]) {
            j -= 1;
        }
        var tmp = arr[i - 1];
        arr[i - 1] = arr[j];
        arr[j] = tmp;

        j = arr.len - 1;
        while (i < j) {
            tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
            i += 1;
            j -= 1;
        }
        return arr;
    }


    pub fn bruteForce(self: *SpringRecord) u32 {
        var working_combinations: u32 = 0;

        var configuration: []u8 = allocator.alloc(u8, self.variables.items.len) catch unreachable;
        var test_springs = allocator.dupe(u8, self.springs) catch unreachable;
        var tested_configurations = std.BufSet.init(allocator);

        for (0..self.variables.items.len) |p| {
            // 1. Initialize configurations
            for(0..configuration.len) |i| {
                if (i <= p) {
                    configuration[i] = '#';
                    continue;
                }
                configuration[i] = '.';
            }

            // 2. Generate possible permutations
            while (true) {
                // 3. Test permutation
                for (0..configuration.len) |ci| {
                    var seq_idx = self.variables.items[ci];
                    var val = configuration[ci];
                    test_springs[seq_idx] = val;
                }
                // std.debug.print("\n    ", .{});
                // self.printSprings(test_springs);
                if (self.testCriteria(test_springs)) {
                    // std.debug.print("\n \x1B[32m✓\x1B[0m", .{});
                    working_combinations += 1;

                    if (!tested_configurations.contains(configuration)) {
                        tested_configurations.insert(configuration) catch unreachable;
                    }
                }
                
                configuration = self.nextPerm(configuration) catch {
                    break;
                };
            }
        }

        if (working_combinations != tested_configurations.count()) {
            std.debug.print("\nPossible working combinations: \x1B[32m{d}\x1B[0m", .{ working_combinations });
            std.debug.print("\nFrom Set: \x1B[32m{d}\x1B[0m", .{ tested_configurations.count() });
        }
        return working_combinations;
    }

    pub fn testCriteria(self: *SpringRecord, springs: []const u8) bool {
        var split_it = std.mem.tokenize(u8, springs, ".");
        var group_counts = std.ArrayList(u8).init(allocator);
        while(split_it.next()) |split| {
            group_counts.append(@intCast(split.len)) catch unreachable;
        }
        return std.mem.eql(u8, group_counts.items, self.numeric);
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

fn part1(input: []const u8) void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var records = std.ArrayList(SpringRecord).init(allocator);

    while(row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, " ");
        const springs = entry_it.next().?;
        const numeric_str = entry_it.next().?;

        var num_it = std.mem.tokenize(u8, numeric_str, ",");
        var numeric = std.ArrayList(u8).init(allocator);
        while(num_it.next()) |v| {
            const n = std.fmt.charToDigit(v[0], 10) catch unreachable;
            numeric.append(n) catch unreachable;
        }
        
        const sprintRecord = SpringRecord{
            .springs = springs,
            .numeric = numeric.items,
        };
        records.append(sprintRecord) catch unreachable;
    }

    var sum: u32 = 0;
    for(0..records.items.len) |i| {
        std.debug.print("\n- {d}", .{ i });
        var record = records.items[i];
        record.findVariables();
        std.debug.print("\n   {any}", .{ record });
        const working_combinations = record.bruteForce();
        sum += working_combinations;
    }

    std.debug.print("\n\nResult: {d}\n", .{ sum });
}

fn part2(input: []const u8) void {
    _ = input;
}

pub fn main() !void {
    try common.runDay(allocator, 12, .PUZZLE, part1, part2);
}
