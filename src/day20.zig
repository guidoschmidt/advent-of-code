const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Modifier = enum {
    FLIP_FLOP,
    CONJUNCTION,

    pub fn format(self: Modifier,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            Modifier.FLIP_FLOP => try writer.print("{c}", .{ '%' }),
            Modifier.CONJUNCTION => try writer.print("{c}", .{ '&' }),
        }
        
    }
};

const Pulse = enum {
    LOW,
    HIGH,

    pub fn format(self: Pulse,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            Pulse.LOW => try writer.print("{c}", .{ 'L' }),
            Pulse.HIGH => try writer.print("{c}", .{ 'H' }),
        }
    }
};

const Module = struct {
    name: []const u8,
    modifier: ?Modifier,
    receiver_list: []Module = undefined,
    state: ?Pulse = null,

    pub fn link(self: *Module, i: usize, module: Module) !void {
        self.receiver_list[i] = module;
    }

    pub fn format(self: Module,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.modifier == null) {
            try writer.print("[{c}] {s} ", .{ '_', self.name, });
        } else {
            try writer.print("[{any}] {s} ", .{ self.modifier, self.name, });
        }
        try writer.print("[{any}]", .{ self.state });
        try writer.print(" {d}", .{ self.receiver_list.len });
    }
};

const SystemState = struct {
    module_map: std.StringHashMap(Module) = undefined,

    pub fn init(self: *SystemState, allocator: Allocator) void {
        self.module_map = std.StringHashMap(Module).init(allocator);
    }

    pub fn addModule(self: *SystemState, module: Module) !void {
        try self.module_map.put(module.name, module);
    }

    pub fn createLinks(self: *SystemState, sender: []const u8, receivers: std.ArrayList([]const u8)) !void {
        const sender_module = self.module_map.get(sender).?;
        for(0..receivers.items.len) |i| {
            const receiver_name = receivers.items[i];
            const receiver = self.module_map.get(receiver_name);
            sender_module.receiver_list[i] = receiver.?;
            // std.debug.print("\n{s} -> {s}", .{ sender_module.name, receiver.?.name });
        }
    }

    pub fn proceedToNextState(self: *SystemState, allocator: Allocator) !SystemState {
        _ = allocator;
        var broadcaster = self.module_map.get("broadcaster").?;
        broadcaster.state = .LOW;
        try self.module_map.put("broadcaster", broadcaster);
        for(broadcaster.receiver_list) |*receiver| {
            std.debug.print("\n    {s} --{any}-→ {s}", .{ broadcaster.name, broadcaster.state, receiver.name });
            receiver.state = broadcaster.state;
            try self.module_map.put(receiver.name, receiver.*);
        }
        return self.*;
    }

    pub fn format(self: SystemState,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        var module_map_it = self.module_map.valueIterator();
        while(module_map_it.next()) |module| {
            try writer.print("\n{any} ", .{ module.* });
        }
    }

};


fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var start_state = SystemState{};
    start_state.init(allocator);

    var module_links = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);

    while(row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, "->");
        var module_str = entry_it.next().?;
        module_str = std.mem.trim(u8, module_str, " ");
        const modifier_char: u8 = module_str[0];
        var modifier: ?Modifier = null;
        const receiver_list_str = entry_it.next().?;
        var receiver_list_it = std.mem.tokenize(u8, receiver_list_str, ", ");
        switch(modifier_char) {
            '%' => {
                module_str = module_str[1..];
                modifier = .FLIP_FLOP;
            },
            '&' => {
                module_str = module_str[1..];
                modifier = .CONJUNCTION;
            },
            else => {}
        }
        var receivers = std.ArrayList([]const u8).init(allocator);
        while(receiver_list_it.next()) |receiver_name| {
            try receivers.append(receiver_name);
        }
        try module_links.put(module_str, receivers);
        
        try start_state.addModule(Module{
            .name = module_str,
            .modifier = modifier,
            .receiver_list = try allocator.alloc(Module, receivers.items.len)
        });
    }

    std.debug.print("\n[Start State]:\n{any}", .{ start_state });

    var key_it = module_links.keyIterator();
    while (key_it.next()) |key| {
        const receivers = module_links.get(key.*).?;
        try start_state.createLinks(key.*, receivers);
    }


    _ = try start_state.proceedToNextState(allocator);
    std.debug.print("\n{any}", .{ start_state });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = input;
    _ = allocator;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    try common.runPart(arena_alloc, 20, .EXAMPLE, part1);
}
