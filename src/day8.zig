const std = @import("std");
const common = @import("./common.zig");
const math = @import("./math.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const LR = struct {
    l: []const u8,
    r: []const u8
};

const Walker = struct {
    counter: u64,
    pos: []u8,
    instr_idx: u16,
};

fn parse(input: []const u8, nodes_map: *std.StringHashMap(LR),
                     lr_instructions: *std.ArrayList(u8)) void {
    var row_it = std.mem.tokenize(u8, input, "\n");
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
}

fn part1(input: []const u8) void {
    var nodes_map = std.StringHashMap(LR).init(allocator);
    var lr_instructions = std.ArrayList(u8).init(allocator);
    defer lr_instructions.deinit();
    defer nodes_map.deinit();

    parse(input, &nodes_map, &lr_instructions);

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
    var nodes_map = std.StringHashMap(LR).init(allocator);
    var lr_instructions = std.ArrayList(u8).init(allocator);
    defer lr_instructions.deinit();
    defer nodes_map.deinit();

    parse(input, &nodes_map, &lr_instructions);

    // Find all start positions ending with 'A'
    var positions = std.ArrayList([]const u8).init(allocator);
    var endings = std.ArrayList([]const u8).init(allocator);
    defer positions.deinit();
    var key_it = nodes_map.keyIterator();
    while (key_it.next()) |k| {
        if (k.*[2] == 'A')
            positions.append(k.*) catch {
                std.log.err("\nERROR: Could not append {s} to positions", .{ k.* });
        };
        if (k.*[2] == 'Z')
            endings.append(k.*) catch {
                std.log.err("\nERROR: Could not append {s} to positions", .{ k.* });
        };
    }

    std.debug.print("\n{d} start positons...", .{ positions.items.len });
    for(positions.items) |pos| {
        std.debug.print("\n{s}", .{ pos });
    }

    std.debug.print("\n{d} end positons...", .{ endings.items.len });
    for(endings.items) |pos| {
        std.debug.print("\n{s}", .{ pos });
    }
    std.debug.print("\n\n", .{});

    var walkers = std.ArrayList(Walker).init(allocator);
    defer walkers.deinit();
    for(0..positions.items.len) |i| {
        const pos = positions.items[i];
        walkers.append(Walker {
            .pos = @constCast(pos),
            .counter = 0,
            .instr_idx = 0
        }) catch {
            std.log.err("\nERROR: could not append to walkers", .{});
        };
        const t = std.Thread.spawn(.{}, walk, .{
            &walkers.items[i],
            &nodes_map,
            &lr_instructions
        }) catch undefined;
        t.join();
    }

    // Calculate least common multiple
    var counters: []u64 = allocator.alloc(u64, walkers.items.len) catch undefined;
    for (0..walkers.items.len) |i| {
        const walker = walkers.items[i];
        std.debug.print("\n[{s}] {d}", .{ walker.pos, walker.counter });
        counters[i] = walker.counter;
    }
    const result = math.lcm(u64, counters);
    std.debug.print("\n{d}", .{ result });
}

fn walk(walker: *Walker, node_map: *std.StringHashMap(LR), lr_instructions: *std.ArrayList(u8)) void {
    walking: while(true) {
        const node = node_map.get(walker.pos).?;
        const lr_instr = lr_instructions.items[walker.instr_idx];
        const new_pos = switch(lr_instr) {
            'L' => node.l,
            'R' => node.r,
            else => unreachable,
        };
        walker.pos.ptr = @constCast(new_pos.ptr);
        walker.instr_idx=@intCast(@mod(walker.instr_idx + 1, lr_instructions.items.len));
        walker.counter+=1;
        if(new_pos[2] == 'Z')
            break :walking;
    }
}

pub fn main() !void {
    try common.runDay(allocator, 8, .PUZZLE, part1, part2);
}
