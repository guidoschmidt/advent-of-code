const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

const History = struct {
    data: std.ArrayList(i32),

    fn last(self: History, data: std.ArrayList(i32)) i32 {
        _ = self;
        return data.items[data.items.len - 1];
    }

    fn extrapolate_forward(self: History, allocator: Allocator, data: std.ArrayList(i32)) i32 {
        var diffs = std.ArrayList(i32).init(allocator);
        var all_zeros = true;
        for(0..data.items.len - 1) |i| {
            const diff = data.items[i+1] - data.items[i];
            diffs.append(diff) catch unreachable;
            all_zeros = all_zeros and diff == 0;
        }
        std.debug.print("\n{any}", .{ diffs.items });
        if (all_zeros) {
            return self.last(diffs);
        }
        return self.extrapolate_forward(allocator, diffs) + self.last(diffs);
    }

    fn extrapolate_backward(self: History, allocator: Allocator, data: std.ArrayList(i32)) i32 {
        var diffs = std.ArrayList(i32).init(allocator);
        var all_zeros = true;
        for(0..data.items.len - 1) |i| {
            const diff = data.items[i+1] - data.items[i];
            diffs.append(diff) catch unreachable;
            all_zeros = all_zeros and diff == 0;
        }
        std.debug.print("\n{any}", .{ diffs.items });
        if (all_zeros) {
            return diffs.items[0];
        }
        return diffs.items[0] - self.extrapolate_backward(allocator, diffs);
    }

    pub fn find_next(self: History, allocator: Allocator) i32 {
        const n = self.data.items[self.data.items.len - 1] + self.extrapolate_forward(allocator, self.data);
        return n; 
    }

    pub fn find_prev(self: History, allocator: Allocator) i32 {
        const n = self.data.items[0] - self.extrapolate_backward(allocator, self.data);
        return n;
    }
};

fn parseSequences(allocator: Allocator, input: []const u8, list: *std.ArrayList(History)) void {
    var row_it = std.mem.tokenize(u8, input, "\n");
    while(row_it.next()) |row| {
        var val_it = std.mem.tokenize(u8, row, " ");
        var history = History {
            .data = std.ArrayList(i32).init(allocator)
        };
        while(val_it.next()) |val| {
            const number = std.fmt.parseInt(i32, val, 10) catch undefined;
            history.data.append(number) catch {
                std.log.err("\nERROR: could not append {d} to data in Sequence.", .{ number });
            };
        }
        list.append(history) catch {
            std.log.err("\nERROR: could not append sequence to list.", .{});
        };
    }
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var seq_list = std.ArrayList(History).init(allocator);
    parseSequences(allocator, input, &seq_list);
    std.debug.print("\n# Sequeces: {d}", .{ seq_list.items.len });

    var sum: i32 = 0;
    for(0..seq_list.items.len) |i| {
        std.debug.print("\n\n{any}", .{ seq_list.items[i].data.items });
        const next = seq_list.items[i].find_next(allocator);
        std.debug.print("\n→ {d}", .{ next });
        sum += next;
    }
    std.debug.print("\n\nResult:\n{d}", .{ sum });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var seq_list = std.ArrayList(History).init(allocator);
    parseSequences(allocator, input, &seq_list);
    std.debug.print("\n# Sequeces: {d}", .{ seq_list.items.len });

    var sum: i32 = 0;
    for(0..seq_list.items.len) |i| {
        std.debug.print("\n\n{any}", .{ seq_list.items[i].data.items });
        const next = seq_list.items[i].find_prev(allocator);
        std.debug.print("\n→ {d}", .{ next });
        sum += next;
    }
    std.debug.print("\n\nResult:\n{d}", .{ sum });
    
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try aoc.runPart(allocator, 2023, 9, .PUZZLE, part1);
    try aoc.runPart(allocator, 2023, 9, .PUZZLE, part2);
}
