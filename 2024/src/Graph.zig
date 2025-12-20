const std = @import("std");
const Allocator = std.mem.Allocator;

allocator: Allocator,
links: std.StringHashMap(std.BufSet),

const Self = @This();

pub fn init(allocator: Allocator) Self {
    return Self{
        .links = std.StringHashMap(std.BufSet).init(allocator),
        .allocator = allocator,
    };
}

pub fn addLink(self: *Self, u: []const u8, v: []const u8) !void {
    if (self.links.contains(u)) {
        try self.links.getPtr(u).?.insert(v);
    } else {
        var bufset = std.BufSet.init(self.allocator);
        try bufset.insert(v);
        try self.links.put(u, bufset);
    }
}

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    var links_it = self.links.iterator();
    while (links_it.next()) |e| {
        const u = e.key_ptr.*;
        try writer.print("\n{s}\n  └[", .{u});
        var v_it = e.value_ptr.iterator();
        while (v_it.next()) |v| {
            try writer.print("{s},", .{v.*});
        }
        try writer.print("]", .{});
    }
}

pub fn toDotFile(self: *Self, allocator: Allocator) !void {
    const file_path = try std.fs.path.join(allocator, &.{ "output", "graph.dot" });
    const file = try std.fs.cwd().createFile(file_path, .{});
    var file_buffer: [1024]u8 = undefined;
    var fw = file.writer(&file_buffer);

    try fw.interface.print("strict digraph G {{", .{});
    var it = self.links.iterator();
    while (it.next()) |e| {
        const u = e.key_ptr.*;
        try fw.interface.print("\n  {s} -> {{", .{u});
        var v_it = e.value_ptr.iterator();
        while (v_it.next()) |v| {
            try fw.interface.print("{s} ", .{v.*});
        }
        try fw.interface.print("}}", .{});
    }
    try fw.interface.print("\n}}", .{});

    // Try to run 'dot' command to compile .dot file to svg
    var child_process = std.process.Child.init(&[_][]const u8{ "dot", "-Tsvg", file_path, "-o", "graph.svg" }, allocator);
    child_process.stdout_behavior = .Pipe;
    child_process.stderr_behavior = .Pipe;
    try child_process.spawn();
    _ = try child_process.wait();
}

pub fn findCliques(self: *Self) void {
    _ = self;
}
