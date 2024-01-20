const std = @import("std");
const common = @import("common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();


const SpringRecord  = struct {
    springs: []const u8 = undefined,
    numeric: []const u8 = undefined,

    pub fn format(self: SpringRecord,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s} — {any}", .{ self.springs, self.numeric });
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

    for(records.items) |record| {
        std.debug.print("\n{any}", .{ record });
    }
}

fn part2(input: []const u8) void {
    _ = input;
}

pub fn main() !void {
    try common.runDay(allocator, 12, .TEST, part1, part2);
}
