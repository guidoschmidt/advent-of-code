const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Node = struct {
    name: []const u8,
    links: std.ArrayList(?*Node),
    contract: u16 = 1,

    pub fn deinit(self: *Node) void {
        self.links.deinit();
    }

    pub fn format(self: Node,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s} [{d}]", .{ self.name, self.contract });
    }

};

const Graph = struct {
    nodes: std.StringHashMap(Node),
    allocator: Allocator,

    pub fn getRandomNode(self: *Graph, rng: *std.rand.Xoshiro256) !*Node {
        var keys_it = self.nodes.keyIterator();

        const idx_a = rng.random().intRangeAtMost(usize, 0, self.nodes.count() - 1);
        var i : usize = 0;
        while (i < idx_a) : (i += 1) {
            _ = keys_it.next();
        }
        const key_a = keys_it.next().?.*;
        std.debug.print("\nRANDOM KEY {s}", .{ key_a });
        return self.nodes.getPtr(key_a).?;

        // _ = rng;
        // var nodes = std.ArrayList(*Node).init(self.allocator);
        // defer nodes.deinit();
        // var it = self.nodes.valueIterator();
        // while (it.next()) |node| {
        //     try nodes.append(node);
        // }

        // std.mem.sort(*Node, nodes.items, {}, comptime struct {
        //     pub fn f(_: void, a: *Node, b: *Node) bool {
        //         return a.links.items.len > b.links.items.len;
        //     }
        //     }.f);
        // return nodes.items[0];
    }

    pub fn addNode(self: *Graph, name: []const u8) !void {
        try self.nodes.put(name, Node {
            .name = std.mem.trim(u8, name, " "),
            .links = std.ArrayList(?*Node).init(self.allocator),
        });
    }

    pub fn addLink(self: *Graph, from: []const u8, to: []const u8) !void {
        if (self.nodes.contains(from) and self.nodes.contains(to)) {
            const from_ptr = self.nodes.getPtr(from);
            const to_ptr = self.nodes.getPtr(to);
            if (from_ptr != null and to_ptr != null) {
                try from_ptr.?.links.append(to_ptr.?);
            }
        }
    }

    pub fn contractLink(self: *Graph, a: []const u8, b: []const u8) !?*Node {
        const contracted_node_name = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ a, b });

        const new_node = Node {
            .name = contracted_node_name,
            .links = std.ArrayList(?*Node).init(self.allocator),
        };
        try self.nodes.put(contracted_node_name, new_node);

        // Create a new consolidated node from both given nodes a and b
        const new_node_ptr = self.nodes.getPtr(contracted_node_name);
        const from_node = self.nodes.getPtr(a);
        const to_node = self.nodes.getPtr(b);
        if (from_node != null and to_node != null) {
            new_node_ptr.?.contract = to_node.?.contract + from_node.?.contract;
            for (from_node.?.links.items) |link| {
                std.debug.print("\nOLD LINK: {s}", .{ link.?.name });
                if (!std.mem.eql(u8, link.?.name, a) and !std.mem.eql(u8, link.?.name, b)) {
                    try new_node_ptr.?.links.append(link);
                }
            }
            for (to_node.?.links.items) |link| {
                std.debug.print("\nOLD LINK: {s}", .{ link.?.name });
                if (!std.mem.eql(u8, link.?.name, a) and !std.mem.eql(u8, link.?.name, b)) {
                    var already_on_new_node_links = false;
                    for (new_node_ptr.?.links.items) |new_node_link| {
                        if (std.mem.eql(u8, link.?.name, new_node_link.?.name)) {
                            already_on_new_node_links = true;
                            break;
                        }
                    }
                    if (!already_on_new_node_links)
                        try new_node_ptr.?.links.append(link);
                }
            }
        }

        // Path old links
        var it = self.nodes.iterator();
        while (it.next()) |entry| {
            var new_node_linked = false;
            var found_idx_a: ?usize = null;
            for (0..entry.value_ptr.links.items.len) |k| {
                if (std.mem.eql(u8, entry.value_ptr.links.items[k].?.name, a)) {
                    found_idx_a = k;
                }
            }
            if (found_idx_a) |remove_at| {
                _ = entry.value_ptr.links.swapRemove(remove_at);
                try entry.value_ptr.links.append(new_node_ptr);
                new_node_linked = true;
            }

            var found_idx_b: ?usize = null;
            for (0..entry.value_ptr.links.items.len) |k| {
                if (std.mem.eql(u8, entry.value_ptr.links.items[k].?.name, b)) {
                    found_idx_b = k;
                }
            }
            if (found_idx_b) |remove_at| {
                _ = entry.value_ptr.links.swapRemove(remove_at);
                if (!new_node_linked)
                    try entry.value_ptr.links.append(new_node_ptr);
            }
        }

        // Remove teh old nodes
        _ = self.nodes.remove(a); 
        _ = self.nodes.remove(b);

        return new_node_ptr;

        // const combinations = .{ .{ from, to }, .{ to, from } };
        // inline for (0..combinations.len) |i| {
        //     const combination = combinations[i];
        //     const a = combination[0];
        //     const b = combination[1];
        //     std.debug.print("\n{s} x {s}", .{ a, b });
        //     // Update links
        //     if (self.nodes.getPtr(a)) |node| {
        //         for (node.links.items) |link| {
        //             if (!std.mem.eql(u8, link.?.name, b) and self.nodes.contains(link.?.*.name)) {
        //                 std.debug.print("\nCollecting links: {s}", .{ link.?.*.name });
        //                 try new_node.links.append(self.nodes.getPtr(link.?.name));
        //             }
        //         }

        //         var found_idx: ?usize = null;
        //         for (0..node.links.items.len) |k| {
        //             if (std.mem.eql(u8, node.links.items[k].?.name, b)) {
        //                 found_idx = k;
        //                 break;
        //             }
        //         }
        //         if (found_idx) |remove_at| {
        //             _ = node.links.swapRemove(remove_at);
        //         }
        //     }
        //     var node_key_it = self.nodes.keyIterator();
        //     while (node_key_it.next()) |key| {
        //         if (self.nodes.getPtr(key.*)) |node| {
        //             var found_idx: ?usize = null;
        //             for (0..node.links.items.len) |r| {
        //                 if (std.mem.eql(u8, a, node.links.items[r].?.name)) {
        //                     found_idx = r;
        //                 }
        //             }
        //             if (found_idx) |remove_at| {
        //                 _ = node.links.swapRemove(remove_at);
        //                 try node.links.append(new_node_ptr);
        //             }
        //         }
        //     }
        //     // Remove node
        //     if (self.nodes.getPtr(a)) |node| {
        //         node.deinit();
        //         _ = self.nodes.remove(a);
        //     }
        // }
    }

    pub fn format(self: Graph,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        var node_it = self.nodes.iterator();
        try writer.print("\nGRAPH--- [{d}]", .{ self.nodes.count() });
        while (node_it.next()) |node| {
            try writer.print("\n{s}", .{ node.value_ptr });
            for (node.value_ptr.links.items) |link| {
                try writer.print("\n -- {any}", .{ link });
            }
        }
    }

};

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var graph = Graph {
        .nodes = std.StringHashMap(Node).init(allocator),
        .allocator = allocator,
    };

    // Collect component names
    var row_it = std.mem.tokenizeAny(u8, input, "\n");
    while(row_it.next()) |row| {
        var config_it = std.mem.tokenizeAny(u8, row, ":");
        const component = config_it.next().?;
        try graph.addNode(component);

        var connections_it = std.mem.tokenizeAny(u8, config_it.next().?, " ");
        while(connections_it.next()) |connection| {
            try graph.addNode(connection);
        }
    }

    // Collect links
    row_it.reset();
    while(row_it.next()) |row| {
        var config_it = std.mem.tokenizeAny(u8, row, ":");
        const component = config_it.next().?;

        var connections_it = std.mem.tokenizeAny(u8, config_it.next().?, " ");
        while(connections_it.next()) |connection| {
            try graph.addLink(component, connection);
        }
    }
    std.debug.print("\n{any}", .{ graph });

    var queque = std.ArrayList(*Node).init(allocator);

    const rng_gen = std.rand.DefaultPrng;
    var rng: std.rand.Xoshiro256 = rng_gen.init(0);
    try queque.append(try graph.getRandomNode(&rng));
    
    while(queque.items.len > 0) {
        const next = queque.pop();
        std.debug.print("\n... Contracting {s}", .{ next });

        if (next.links.items.len == 0) {
            try queque.append(try graph.getRandomNode(&rng));
            continue;
        }

        // std.mem.sort(?*Node, next.links.items, {}, comptime struct {
        //     pub fn f(_: void, a: ?*Node, b: ?*Node) bool {
        //         return a.?.contract < b.?.contract;
        //     }
        //     }.f);
        const random_link_idx = rng.random().intRangeAtMost(usize, 0, next.links.items.len - 1);
        const next_link = next.links.items[random_link_idx].?.*.name;
        const node_b = graph.nodes.get(next_link).?;

        std.debug.print("<---{s}", .{ node_b.name });
        if (try graph.contractLink(next.name, node_b.name)) |next_node| {
            if (next_node.links.items.len > 0) {
                try queque.append(next_node);
            }
            else {
                try queque.append(try graph.getRandomNode(&rng));
            }
        } else {
            try queque.append(try graph.getRandomNode(&rng));
        }

        std.debug.print("\n{any}", .{ graph });
        // common.blockAskForNext();
        if (graph.nodes.count() < 3) break;
    }


    std.debug.print("\n{any}", .{ graph });

    // Cratea a GraphViz file for visualization
    const file_path = "day25.dot";
    const file = try std.fs.cwd().createFile(file_path, .{});
    var fw = file.writer();

    try fw.print("graph G {{", .{});
    var it = graph.nodes.keyIterator();
    while (it.next()) |key| {
        if(graph.nodes.get(key.*)) |node| {
            try fw.print("\n \"{s}\"", .{ node.name });
            for (node.links.items) |link| {
                if (link != null)
                    try fw.print(" -- \"{s}\"", .{ link.?.name });
            }
        }
    }
    try fw.print("\n}}", .{});

    var node_it = graph.nodes.valueIterator();
    const a = node_it.next();
    const b = node_it.next();
    std.debug.print("\n\n {d} × {d}\n", .{ a.?.contract, b.?.contract });
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = gpa;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    try common.runPart(arena.allocator(), 25, .EXAMPLE, part1);
}
