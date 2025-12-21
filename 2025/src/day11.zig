const std = @import("std");
const aoc = @import("aoc");

const DAY: u5 = 11;

const Allocator = std.mem.Allocator;
const log = std.log;

const Node = struct {
    name: []const u8,
    connections: std.array_list.Managed([]const u8),

    pub fn format(self: Node, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{s}\n", .{self.name});
        for (self.connections.items) |c| {
            try writer.print("  -- {s}\n", .{c});
        }
    }
};

const NodePath = struct {
    path: std.array_list.Managed(*Node),

    pub fn init(allocator: Allocator, start: *Node) !NodePath {
        var node_path: NodePath = .{
            .path = .init(allocator),
        };
        try node_path.path.append(start);
        return node_path;
    }

    pub fn format(self: NodePath, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (self.path.items) |p| {
            try writer.print("{s} → ", .{p.name});
        }
    }
};

fn part1(allocator: Allocator) anyerror!void {
    const input = @embedFile("example-11");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    var device_map: std.hash_map.StringHashMap(Node) = .init(allocator);
    defer device_map.deinit();

    var reader: std.Io.Reader = .fixed(input);
    while (try reader.takeDelimiter('\n')) |line| {
        const colon = std.mem.indexOf(u8, line, ":") orelse @panic(": not found");
        const device_name = line[0..colon];
        const connections = line[colon + 1 ..];
        var connections_it = std.mem.splitSequence(u8, connections, " ");
        var node: Node = .{
            .name = device_name,
            .connections = .init(allocator),
        };
        while (connections_it.next()) |connection| {
            if (connection.len == 0) continue;
            try node.connections.append(connection);
        }
        try device_map.put(device_name[0..3], node);
    }

    var stack: std.array_list.Managed(*Node) = .init(allocator);
    defer stack.deinit();
    try stack.append(device_map.getPtr("you").?);

    var result: usize = 0;
    while (stack.pop()) |next| {
        std.debug.print("[{d}] Next: {f}\n", .{ stack.items.len, next });
        for (next.connections.items) |connection| {
            if (std.mem.eql(u8, connection, "out")) {
                result += 1;
                continue;
            }
            if (device_map.getPtr(connection)) |ptr| {
                try stack.append(ptr);
            }
        }
    }
    std.debug.print("Result: {d}\n", .{result});
}

fn part2(allocator: Allocator) anyerror!void {
    const input = @embedFile("example-11");
    std.debug.print("--- INPUT---\n{s}\n------------\n", .{input});

    var device_map: std.hash_map.StringHashMap(Node) = .init(allocator);
    defer device_map.deinit();

    var reader: std.Io.Reader = .fixed(input);
    while (try reader.takeDelimiter('\n')) |line| {
        const colon = std.mem.indexOf(u8, line, ":") orelse @panic(": not found");
        const device_name = line[0..colon];
        const connections = line[colon + 1 ..];
        var connections_it = std.mem.splitSequence(u8, connections, " ");
        var node: Node = .{
            .name = device_name,
            .connections = .init(allocator),
        };
        while (connections_it.next()) |connection| {
            if (connection.len == 0) continue;
            try node.connections.append(connection);
        }
        try device_map.put(device_name[0..3], node);
    }

    var paths: std.array_list.Managed(NodePath) = .init(allocator);
    defer paths.deinit();

    var stack: std.array_list.Managed(*Node) = .init(allocator);
    defer stack.deinit();
    try stack.append(device_map.getPtr("you").?);

    while (stack.pop()) |next| {
        if (std.mem.eql(u8, next.name, "out")) break;
        std.debug.print("[{d}] Next: {f}\n", .{ stack.items.len, next });
        if (next.connections.items.len > 0) {
            if (device_map.getPtr(next.connections.items[0])) |ptr| {
                try stack.append(ptr);
            }
        }

        // for (next.connections.items) |connection| {
        //     if (std.mem.eql(u8, connection, "out")) {
        //         result += 1;
        //         continue;
        //     }
        //     if (device_map.getPtr(connection)) |ptr| {
        //         try stack.append(ptr);
        //     }
        // }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, part1);
    try aoc.runPart(allocator, part2);
}
