const std = @import("std");
const aoc = @import("aoc");
const VectorSet = @import("libs").VectorSet;

const DAY: u5 = 8;

const Allocator = std.mem.Allocator;
const log = std.log;

fn Box(comptime T: type) type {
    return struct {
        id: usize,
        pos: @Vector(3, T),

        pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("[{d: >4}] {d: >6}", .{ self.id, self.pos });
        }
    };
}

fn Connection(comptime T: type) type {
    return struct {
        a: Box(T),
        b: Box(T),
        d: T,

        pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("{f}---{f} [distance: {d: >10.3}]", .{ self.a, self.b, self.d });
        }
    };
}

const Circuit = struct {
    ids: std.bit_set.DynamicBitSet,

    pub fn initEmpty(allocator: Allocator) !Circuit {
        return Circuit{
            .ids = try std.bit_set.DynamicBitSet.initEmpty(allocator, 4096),
        };
    }

    pub fn init(allocator: Allocator, start: Box(f32)) !Circuit {
        var ids = try std.bit_set.DynamicBitSet.initEmpty(allocator, 4096);
        ids.set(start.id);
        return Circuit{
            .ids = ids,
        };
    }

    pub fn contains(self: *const Circuit, b: Box(f32)) bool {
        return self.ids.isSet(b.id);
    }

    pub fn merge(self: *Circuit, c: Circuit) void {
        var it = c.ids.iterator(.{});
        while (it.next()) |id| {
            self.ids.set(id);
        }
    }

    pub fn format(self: Circuit, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Circuit [{d}]\n", .{self.ids.count()});
        var it = self.ids.iterator(.{});
        while (it.next()) |c| {
            std.debug.print("    + {d}\n", .{c});
        }
    }

    pub fn deinit(self: *Circuit) void {
        self.ids.deinit();
    }
};

fn distance(comptime T: type, a: @Vector(3, T), b: @Vector(3, T)) T {
    const v = @abs(b - a);
    return @sqrt(@reduce(.Add, v * v));
}

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-08");

    var reader: std.Io.Reader = .fixed(input);

    var junction_boxes: std.array_list.Managed(Box(f32)) = .init(allocator);
    defer junction_boxes.deinit();

    var idx: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        var coords_it = std.mem.splitScalar(u8, line, ',');
        var coord: @Vector(3, f32) = @splat(0);
        var i: usize = 0;
        while (coords_it.next()) |str| : (i += 1) {
            const v = try std.fmt.parseFloat(f32, str);
            std.debug.assert(v != 0);
            coord[i] = v;
        }
        std.debug.assert(i <= 3);
        try junction_boxes.append(.{
            .id = idx,
            .pos = coord,
        });
        idx += 1;
    }

    var connections: std.array_list.Managed(Connection(f32)) = .init(allocator);
    defer connections.deinit();

    var used_boxes: std.bit_set.DynamicBitSet = try .initEmpty(allocator, 4096);
    defer used_boxes.deinit();
    var circuits: std.array_list.Managed(Circuit) = .init(allocator);
    defer circuits.deinit();
    defer for (circuits.items) |*c| c.deinit();

    for (0..junction_boxes.items.len) |i| {
        for (i..junction_boxes.items.len) |j| {
            const a = junction_boxes.items[i];
            const b = junction_boxes.items[j];
            const d = distance(f32, a.pos, b.pos);
            if (!used_boxes.isSet(a.id)) {
                try circuits.append(try .init(allocator, a));
                used_boxes.set(a.id);
            }
            if (!used_boxes.isSet(b.id)) {
                try circuits.append(try .init(allocator, b));
                used_boxes.set(b.id);
            }
            if (d == 0) continue;
            try connections.append(.{
                .a = a,
                .b = b,
                .d = d,
            });
        }
    }

    std.mem.sort(Connection(f32), connections.items, {}, comptime struct {
        pub fn f(_: void, a: Connection(f32), b: Connection(f32)) bool {
            return a.d > b.d;
        }
    }.f);

    const limit: usize = 1000;
    var i: usize = 0;
    while (connections.pop()) |next| : (i += 1) {
        if (i >= limit) break;
        std.debug.print("[{d: >5}] {f}\n", .{ i, next });

        var circuit_a: ?Circuit = null;
        var count: usize = circuits.items.len;
        for (0..count) |c| {
            const circuit = circuits.items[c];
            if (circuit.contains(next.a) and circuit.contains(next.b)) continue;
            if (circuit.contains(next.a)) {
                circuit_a = circuits.swapRemove(c);
                count = circuits.items.len;
                break;
            }
        }
        std.debug.print("Circuit A: {any}\n", .{circuit_a});

        var circuit_b: ?Circuit = null;
        for (0..circuits.items.len) |c| {
            const circuit = circuits.items[c];
            if (circuit.contains(next.a) and circuit.contains(next.b)) continue;
            if (circuit.contains(next.b)) {
                circuit_b = circuits.swapRemove(c);
                break;
            }
        }
        std.debug.print("Circuit B: {any}\n", .{circuit_b});

        if (circuit_a != null and circuit_b != null) {
            std.debug.print(">>>>> Merge!\n", .{});
            defer circuit_a.?.deinit();
            defer circuit_b.?.deinit();
            var merged: Circuit = try .initEmpty(allocator);
            merged.merge(circuit_a.?);
            merged.merge(circuit_b.?);
            try circuits.append(merged);
        }

        // std.debug.print("\n------\n# Circuits: {d}\n", .{circuits.items.len});
        // for (0..circuits.items.len) |c| {
        //     std.debug.print("@{d} {f}\n", .{ c, circuits.items[c] });
        // }
        // aoc.blockAskForNext();
    }

    std.mem.sort(Circuit, circuits.items, {}, comptime struct {
        pub fn f(_: void, a: Circuit, b: Circuit) bool {
            return a.ids.count() > b.ids.count();
        }
    }.f);

    var result: usize = 1;
    var total: usize = 0;
    std.debug.print("\n------\n# Circuits: {d}\n", .{circuits.items.len});
    for (0..circuits.items.len) |c| {
        if (c >= 3) break;
        total += circuits.items[c].ids.count();
        result *= circuits.items[c].ids.count();
        std.debug.print("[{d: >3}]\n{f}\n", .{ c, circuits.items[c] });
    }

    std.debug.print("Total connections: {d}\n", .{total});
    std.debug.print("Result: {d}\n", .{result});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("puzzle-08");

    var reader: std.Io.Reader = .fixed(input);

    var junction_boxes: std.array_list.Managed(Box(f32)) = .init(allocator);
    defer junction_boxes.deinit();

    var idx: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        var coords_it = std.mem.splitScalar(u8, line, ',');
        var coord: @Vector(3, f32) = @splat(0);
        var i: usize = 0;
        while (coords_it.next()) |str| : (i += 1) {
            const v = try std.fmt.parseFloat(f32, str);
            std.debug.assert(v != 0);
            coord[i] = v;
        }
        std.debug.assert(i <= 3);
        try junction_boxes.append(.{
            .id = idx,
            .pos = coord,
        });
        idx += 1;
    }

    var connections: std.array_list.Managed(Connection(f32)) = .init(allocator);
    defer connections.deinit();

    var used_boxes: std.bit_set.DynamicBitSet = try .initEmpty(allocator, 4096);
    defer used_boxes.deinit();
    var circuits: std.array_list.Managed(Circuit) = .init(allocator);
    defer circuits.deinit();
    defer for (circuits.items) |*c| c.deinit();

    for (0..junction_boxes.items.len) |i| {
        for (i..junction_boxes.items.len) |j| {
            const a = junction_boxes.items[i];
            const b = junction_boxes.items[j];
            const d = distance(f32, a.pos, b.pos);
            if (!used_boxes.isSet(a.id)) {
                try circuits.append(try .init(allocator, a));
                used_boxes.set(a.id);
            }
            if (!used_boxes.isSet(b.id)) {
                try circuits.append(try .init(allocator, b));
                used_boxes.set(b.id);
            }
            if (d == 0) continue;
            try connections.append(.{
                .a = a,
                .b = b,
                .d = d,
            });
        }
    }

    std.mem.sort(Connection(f32), connections.items, {}, comptime struct {
        pub fn f(_: void, a: Connection(f32), b: Connection(f32)) bool {
            return a.d > b.d;
        }
    }.f);

    var result: usize = 0;
    var i: usize = 0;
    while (connections.pop()) |next| : (i += 1) {
        var circuit_a: ?Circuit = null;
        var count: usize = circuits.items.len;
        for (0..count) |c| {
            const circuit = circuits.items[c];
            if (circuit.contains(next.a) and circuit.contains(next.b)) continue;
            if (circuit.contains(next.a)) {
                circuit_a = circuits.swapRemove(c);
                count = circuits.items.len;
                break;
            }
        }

        var circuit_b: ?Circuit = null;
        for (0..circuits.items.len) |c| {
            const circuit = circuits.items[c];
            if (circuit.contains(next.a) and circuit.contains(next.b)) continue;
            if (circuit.contains(next.b)) {
                circuit_b = circuits.swapRemove(c);
                break;
            }
        }

        if (circuit_a != null and circuit_b != null) {
            defer circuit_a.?.deinit();
            defer circuit_b.?.deinit();
            var merged: Circuit = try .initEmpty(allocator);
            merged.merge(circuit_a.?);
            merged.merge(circuit_b.?);
            try circuits.append(merged);
        }

        if (circuits.items.len == 1) {
            result = @as(usize, @intFromFloat(next.a.pos[0])) * @as(usize, @intFromFloat(next.b.pos[0]));
            break;
        }
    }

    std.debug.print("Result: {d}\n", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
