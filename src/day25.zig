const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Link = struct {
    a: []const u8,
    b: []const u8,
};

fn belongsToGroup(group_map: *std.AutoHashMap(u8, std.BufSet), comp: []const u8) ?u8 {
    var belongs_to_group: ?u8 = null;
    var group_map_it = group_map.*.iterator();
    while(group_map_it.next()) |group| {
        var group_items_it = group.value_ptr.*.iterator();
        while (group_items_it.next()) |group_item| {
            if (std.mem.eql(u8, group_item.*, comp)) {
                belongs_to_group = group.key_ptr.*;
            }
        }
    }
    return belongs_to_group;
}

fn findGroups(gpa: Allocator, comp_conn_map: std.StringHashMap(std.ArrayList([]const u8))) !void {
    var group_map = std.AutoHashMap(u8, std.BufSet).init(gpa);

    var comp_map_it = comp_conn_map.iterator();
    while (comp_map_it.next()) |e| {
        const comp_name =  e.key_ptr.*;
        if (group_map.count() == 0) {
            var set = std.BufSet.init(gpa);
            try set.insert(comp_name);
            for (e.value_ptr.*.items) |conn| {
                try set.insert(conn);
            }
            try group_map.put(0, set);
            continue;
        }

        var group_id: ?u8 = null;
        for (e.value_ptr.*.items) |conn| {
            group_id = belongsToGroup(&group_map, conn);
            if (group_id != null) break;
        }
        if (group_id != null) {
            var group_components = group_map.get(group_id.?).?;
            try group_components.insert(comp_name);
            try group_map.put(group_id.?, group_components);
        } else {
            var new_set = std.BufSet.init(gpa);
            try new_set.insert(comp_name);
            try group_map.put(@intCast(group_map.count()), new_set);
        }
    }

    for(0..group_map.count()) |g_id| {
        const g = group_map.get(@intCast(g_id)).?;
        std.debug.print("\n\nGroup {d} [{d}]\n    ", .{ g_id, g.count() });
        var group_comp_it = g.iterator();
        while (group_comp_it.next()) |c| {
            std.debug.print("{s},", .{ c.* });
        }
    }
}

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var component_connection_map = std.StringHashMap(std.ArrayList([]const u8)).init(gpa);

    var row_it = std.mem.tokenizeAny(u8, input, "\n");
    while(row_it.next()) |row| {
        var config_it = std.mem.tokenizeAny(u8, row, ":");
        var component_str = config_it.next().?;
        var connections_it = std.mem.tokenizeAny(u8, config_it.next().?, " ");
        var local_connections_list = std.ArrayList([]const u8).init(gpa);
        while (connections_it.next()) |connection| {
            try local_connections_list.append(connection);
        }

        if (component_connection_map.get(component_str) == null) {
            try component_connection_map.put(component_str, local_connections_list);
            for (local_connections_list.items) |c| {
                var other_list = std.ArrayList([]const u8).init(gpa);
                try other_list.append(component_str);
                try component_connection_map.put(c, other_list);
            }
            continue;
        }

        var prev_map_value = component_connection_map.get(component_str).?;
        for (local_connections_list.items) |conn| {
            try prev_map_value.append(conn);
        }
        try component_connection_map.put(component_str, prev_map_value);
    }

    var map_it = component_connection_map.iterator();
    while(map_it.next()) |e| {
        std.debug.print("\n{s} [{d}]", .{ e.key_ptr.*, e.value_ptr.*.items.len,  });
        for (e.value_ptr.*.items) |c| {
            std.debug.print("\n    ⚈-⚈ {s}", .{ c });
        }
    }
    std.debug.print("\n{d} components", .{ component_connection_map.count() });

    try findGroups(gpa, component_connection_map);
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
