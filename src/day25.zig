const std = @import("std");
const common = @import("common.zig");

const Component = struct {
    name: []const u8,
    connections: std.ArrayList([]const u8),
};

const Allocator = std.mem.Allocator;

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var component_list = std.ArrayList(Component).init(gpa);

    var row_it = std.mem.tokenizeAny(u8, input, "\n");
    while(row_it.next()) |row| {
        var config_it = std.mem.tokenizeAny(u8, row, ":");
        var component = config_it.next().?;
        var connections_it = std.mem.tokenizeAny(u8, config_it.next().?, " ");
        var local_connections_list = std.ArrayList([]const u8).init(gpa);
        while (connections_it.next()) |connection| {
            try local_connections_list.append(connection);
        }
        try component_list.append(Component {
            .name = component,
            .connections = local_connections_list,
        });
    }

    for (component_list.items) |comp| {
        std.debug.print("\n{s}", .{ comp.name });
        for (comp.connections.items) |conn| {
            std.debug.print("\n  ⚈---⚈ {s}", .{ conn });
        }
    }
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = gpa;
    _ = input;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runPart(gpa, 25, .EXAMPLE, part1);
}
