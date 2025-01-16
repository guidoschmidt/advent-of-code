const std = @import("std");
const aoc = @import("aoc");

const DAY: u8 = 24;
const Allocator = std.mem.Allocator;
const log = std.log;

const Op = enum(u2) {
    AND,
    OR,
    XOR,

    pub fn fromChar(input: u8) Op {
        return switch (input) {
            'A' => Op.AND,
            'O' => Op.OR,
            'X' => Op.XOR,
            else => unreachable,
        };
    }

    pub fn format(self: Op, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .AND => try writer.print("&", .{}),
            .OR => try writer.print("|", .{}),
            .XOR => try writer.print("^", .{}),
        }
    }
};

const Gate = struct {
    in_a: []const u8,
    in_b: []const u8,
    op: Op,
    out: []const u8,

    pub fn format(self: Gate, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s} {any} {s} → {s}", .{ self.in_a, self.op, self.in_b, self.out });
    }
};

const System = struct {
    wires: std.BufSet,
    output_wires: [][]const u8,
    output_wire_values: []u8,
    wire_values: std.StringHashMap(u1),
    gates: std.ArrayList(Gate),

    pub fn run(self: *System) !void {
        // log.info("{any}", .{self});

        var all_output_wires_set: bool = true;
        for (0..self.output_wires.len) |i| {
            const output_wire = self.output_wires[i];
            const output_wire_val = self.wire_values.get(output_wire);
            if (output_wire_val != null) {
                self.output_wire_values[i] = @intCast(output_wire_val.?);
            }
            log.info("Value of {s}: {?}", .{ output_wire, output_wire_val });
            all_output_wires_set = all_output_wires_set and self.wire_values.get(output_wire) != null;
        }

        if (all_output_wires_set) {
            log.info("All z- wires set!", .{});

            var bit_set = std.bit_set.IntegerBitSet(100).initEmpty();
            for (0..self.output_wire_values.len) |i| {
                log.info("{d}: {d}", .{ i, self.output_wire_values[i] });
                if (self.output_wire_values[i] == 1)
                    bit_set.set(i);
            }

            std.debug.print("\nResult: {b} → {d}", .{ bit_set.mask, bit_set.mask });
            return;
        }

        for (self.gates.items) |gate| {
            const va = self.wire_values.get(gate.in_a);
            const vb = self.wire_values.get(gate.in_b);
            const op = gate.op;
            if (va != null and vb != null) {
                const v_out = switch (op) {
                    .AND => va.? & vb.?,
                    .OR => va.? | vb.?,
                    .XOR => va.? ^ vb.?,
                };
                try self.wire_values.put(gate.out, v_out);
            }
        }

        // aoc.blockAskForNext();
        try self.run();
    }

    pub fn format(self: System, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\nWIRES:", .{});
        var wires_it = self.wires.iterator();
        while (wires_it.next()) |wire| {
            try writer.print("\n{s}: {?}", .{ wire.*, self.wire_values.get(wire.*) });
        }
        try writer.print("\nOUTPUT WIRES:", .{});
        for (self.output_wires) |output_wire| {
            try writer.print("\n  → {s}: {?}", .{ output_wire, self.wire_values.get(output_wire) });
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !System {
    var part_it = std.mem.splitSequence(u8, input, "\n\n");

    // Wires
    var wires = std.BufSet.init(allocator);
    var output_wires_set = std.BufSet.init(allocator);
    defer output_wires_set.deinit();
    var wire_values = std.StringHashMap(u1).init(allocator);

    const wires_input = part_it.next().?;
    var wires_it = std.mem.splitSequence(u8, wires_input, "\n");
    while (wires_it.next()) |wire| {
        var wire_it = std.mem.splitSequence(u8, wire, ":");
        const name = wire_it.next().?;
        try wires.insert(name);
        if (name[0] == 'z')
            try output_wires_set.insert(name);

        const value = std.mem.trim(u8, wire_it.next().?, " ");
        const bit_value = try std.fmt.parseInt(u1, value, 2);
        try wire_values.put(name, bit_value);
    }

    // Gates
    var gates = std.ArrayList(Gate).init(allocator);

    const gates_input = part_it.next().?;
    var gates_it = std.mem.splitSequence(u8, gates_input, "\n");
    while (gates_it.next()) |gate_str| {
        if (gate_str.len == 0) break;
        var gate_result_it = std.mem.splitSequence(u8, gate_str, "->");
        const lhs = gate_result_it.next().?;
        var lhs_it = std.mem.splitSequence(u8, lhs, " ");
        const in_a = lhs_it.next().?;
        const op = Op.fromChar(lhs_it.next().?[0]);
        const in_b = lhs_it.next().?;

        try wires.insert(in_a);
        if (in_a[0] == 'z')
            try output_wires_set.insert(in_a);
        try wires.insert(in_b);
        if (in_b[0] == 'z')
            try output_wires_set.insert(in_b);

        const rhs = gate_result_it.next().?;
        const output_name = std.mem.trim(u8, rhs, " ");
        try wires.insert(output_name);
        if (output_name[0] == 'z')
            try output_wires_set.insert(output_name);

        const gate = Gate{
            .in_a = in_a,
            .in_b = in_b,
            .op = op,
            .out = output_name,
        };
        log.info("{any}", .{gate});
        try gates.append(gate);
    }

    var output_wires_list = try allocator.alloc([]const u8, output_wires_set.count());
    var output_wires_set_it = output_wires_set.iterator();
    var i: usize = 0;
    while (output_wires_set_it.next()) |output_wire| : (i += 1) {
        output_wires_list[i] = try allocator.dupe(u8, output_wire.*);
    }

    std.mem.sort([]const u8, output_wires_list, {}, comptime struct {
        pub fn f(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.order(u8, lhs, rhs) == .lt;
        }
    }.f);

    return System{
        .wires = wires,
        .output_wires = output_wires_list,
        .output_wire_values = try allocator.alloc(u8, output_wires_list.len),
        .wire_values = wire_values,
        .gates = gates,
    };
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var system = try parseInput(allocator, input);
    try system.run();
    // log.info("{any}", .{system});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
