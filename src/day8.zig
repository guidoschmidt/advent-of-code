const std = @import("std");
const common = @import("./common.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const LR = struct {
    l: []const u8,
    r: []const u8
};

fn part1(input: []const u8) void {
    var row_it = std.mem.tokenize(u8, input, "\n");
    var lr_instructions = std.ArrayList(u8).init(allocator);
    var nodes_map = std.StringHashMap(LR).init(allocator);
    while (row_it.next())|row| {
        // LR instructions
        if (!std.mem.containsAtLeast(u8, row, 1, "=")) {
            for(row) |i| {
                lr_instructions.append(i) catch {
                    std.log.err("\nERROR: could not append {c} to instruction list!", .{ i });
                };
            }
            continue;
        }
        // Nodes
        var assign_it = std.mem.tokenize(u8, row, "=");
        var l_side = std.mem.trim(u8, assign_it.next().?, " ");
        var r_side = assign_it.next().?;
        r_side = std.mem.trim(u8, r_side, " ");
        var lr_values_it = std.mem.split(u8, r_side[1..r_side.len-1], ",");
        var l_value = std.mem.trim(u8, lr_values_it.next().?, " ");
        var r_value = std.mem.trim(u8, lr_values_it.next().?, " ");
        nodes_map.put(l_side, LR{
            .l = l_value,
            .r = r_value,
        }) catch {
            std.log.err("\nCould not append LR item to nodes map", .{});
        };
    }

    var pos: []const u8 = "AAA";
    var idx: u16 = 0;
    var counter: u16 = 0;
    while(!std.mem.eql(u8, pos, "ZZZ")) : (idx = @intCast(@mod(idx + 1, lr_instructions.items.len))) {
        const node = nodes_map.get(pos).?;
        const instr = lr_instructions.items[idx];
        pos = switch(instr) {
            'L' => node.l,
            'R' => node.r,
            else => unreachable,
        };
        std.debug.print("\n{s} [L: {s}, R: {s}] → {c} ", .{ pos, node.l, node.r, instr });
        counter+=1;
    }
    std.debug.print("\nResult: {d}", .{ counter });
    
}

fn part2(input: []const u8) void {
    _ = input;
    
}

pub fn main() !void {
    try common.runDay(allocator, 8, .PUZZLE, part1, part2);
}
