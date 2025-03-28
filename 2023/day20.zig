const std = @import("std");
const aoc = @import("aoc");
const math = @import("math");

const Allocator = std.mem.Allocator;

const Pulse = enum {
    LOW,
    HIGH,

    pub fn format(self: Pulse, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .LOW => try writer.print("{c}", .{'L'}),
            .HIGH => try writer.print("{c}", .{'H'}),
        }
    }
};

const NodeType = enum {
    FLIP_FLOP,
    CONJUNCTION,
    BROADCAST,
    OTHER,

    pub fn format(self: NodeType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .FLIP_FLOP => try writer.print("{s}", .{"FLFL"}),
            .CONJUNCTION => try writer.print("{s}", .{"CONJ"}),
            .BROADCAST => try writer.print("{s}", .{"BRDC"}),
            .OTHER => try writer.print("{s}", .{"OTHR"}),
        }
    }
};

const NodeModule = union(NodeType) {
    FLIP_FLOP: bool,
    CONJUNCTION: std.StringHashMap(Pulse),
    BROADCAST: bool,
    OTHER: bool,

    pub fn format(self: NodeModule, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .FLIP_FLOP => try writer.print("{any}", .{NodeType.FLIP_FLOP}),
            .CONJUNCTION => try writer.print("{any}", .{NodeType.CONJUNCTION}),
            .BROADCAST => try writer.print("{any}", .{NodeType.BROADCAST}),
            .OTHER => try writer.print("{any}", .{NodeType.OTHER}),
        }
    }
};

const Transfer = struct {
    from: []const u8,
    to: *Node,
    pulse: Pulse,
};

const Node = struct {
    name: []const u8,
    inputs: std.ArrayList(*Node),
    outputs: std.ArrayList(*Node),
    module: NodeModule,
    state: ?Pulse = undefined,

    pub fn format(self: Node, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n{s} [{any}]", .{ self.name, self.module });

        try writer.print("\n  IN: {d}", .{self.inputs.items.len});
        for (self.inputs.items) |in| {
            try writer.print("\n   ← {s}", .{in.*.name});
        }

        try writer.print("\n  OUT: {d}", .{self.outputs.items.len});
        for (self.outputs.items) |out| {
            try writer.print("\n   → {s}", .{out.*.name});
        }
    }

    pub fn addOutput(self: *Node, out_node: *Node) !void {
        var found = false;
        for (self.outputs.items) |existing_output| {
            if (std.mem.eql(u8, existing_output.*.name, out_node.name)) {
                found = true;
                break;
            }
        }
        if (!found) {
            try self.outputs.append(out_node);
        }
    }

    pub fn addInput(self: *Node, in_node: *Node) !void {
        var found = false;
        for (self.inputs.items) |existing_input| {
            if (std.mem.eql(u8, existing_input.*.name, in_node.name)) {
                found = true;
                break;
            }
        }
        if (!found) {
            try self.inputs.append(in_node);
        }
    }

    pub fn process(self: *Node, in: Pulse, from_input: []const u8, transfers: *std.ArrayList(Transfer)) !void {
        const out = switch (self.module) {
            .BROADCAST => self.processBroadcast(in),
            .FLIP_FLOP => |ff_state| self.processFlipFlop(in, ff_state),
            .CONJUNCTION => self.processConjunction(in, from_input),
            .OTHER => null,
        };
        self.state = out;
        if (out != null) {
            for (self.outputs.items) |output| {
                try transfers.append(Transfer{
                    .from = self.name,
                    .pulse = out.?,
                    .to = output,
                });
            }
        }
    }

    fn processBroadcast(self: *Node, in: Pulse) Pulse {
        _ = self;
        return in;
    }

    fn processFlipFlop(self: *Node, in: Pulse, ff_state: bool) ?Pulse {
        if (in == .HIGH) return null;
        var send_pulse: Pulse = .LOW;
        if (ff_state == false) {
            self.module.FLIP_FLOP = true;
            send_pulse = .HIGH;
        }
        if (ff_state == true) {
            self.module.FLIP_FLOP = false;
        }

        return send_pulse;
    }

    fn processConjunction(self: *Node, in: Pulse, from_input: []const u8) Pulse {
        self.module.CONJUNCTION.put(from_input, in) catch {
            @panic("Could not put state on conjunction module!");
        };
        var high_pulse_count: u8 = 0;
        var conj_it = self.module.CONJUNCTION.keyIterator();
        while (conj_it.next()) |input_module_name| {
            const rem_value = self.module.CONJUNCTION.get(input_module_name.*).?;
            // std.debug.print("\n    {s}: {any}", .{ input_module_name.*, rem_value });
            if (rem_value == .HIGH)
                high_pulse_count += 1;
        }
        const send_pulse: Pulse = if (high_pulse_count == self.module.CONJUNCTION.count())
            .LOW
        else
            .HIGH;

        return send_pulse;
    }
};

const SystemState = struct {
    allocator: Allocator = undefined,
    module_dict: std.StringHashMap(Node) = undefined,
    low_pulses_sent: u64 = 0,
    high_pulses_sent: u64 = 0,
    final_output_modules: ?std.ArrayList(u64) = undefined,

    pub fn format(self: SystemState, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n--- SYSTEM STATE ---", .{});
        try writer.print("\n LOW  pulses sent: {d}", .{self.low_pulses_sent});
        try writer.print("\n HIGH pulses sent: {d}", .{self.high_pulses_sent});
        var module_it = self.module_dict.keyIterator();
        while (module_it.next()) |module_name| {
            const module = self.module_dict.get(module_name.*);
            try writer.print("\n{any}", .{module});
        }
    }

    pub fn pressButton(self: *SystemState, i: usize) !bool {
        var broadcaster = self.module_dict.get("broadcaster").?;

        const start = Transfer{
            .from = "button",
            .to = &broadcaster,
            .pulse = .LOW,
        };

        var transfers = std.ArrayList(Transfer).init(self.allocator);
        try transfers.append(start);

        const low_pulse_to_rx = false;
        while (transfers.items.len > 0) {
            const next = transfers.orderedRemove(0);

            switch (next.pulse) {
                .LOW => self.low_pulses_sent += 1,
                .HIGH => self.high_pulses_sent += 1,
            }

            // zl, xf, xn, qn
            const is_zl = std.mem.eql(u8, next.from, "zl");
            const is_xf = std.mem.eql(u8, next.from, "xf");
            const is_xn = std.mem.eql(u8, next.from, "xn");
            const is_qn = std.mem.eql(u8, next.from, "qn");
            if (is_zl and next.pulse == .HIGH) {
                std.debug.print("\nHIGH to {s}: {d}", .{ next.from, i });
                try self.final_output_modules.?.append(i + 1);
                aoc.blockAskForNext();
            }
            if (is_xf and next.pulse == .HIGH) {
                std.debug.print("\nHIGH to {s}: {d}", .{ next.from, i });
                try self.final_output_modules.?.append(i + 1);
                aoc.blockAskForNext();
            }
            if (is_xn and next.pulse == .HIGH) {
                std.debug.print("\nHIGH to {s}: {d}", .{ next.from, i });
                try self.final_output_modules.?.append(i + 1);
                aoc.blockAskForNext();
            }
            if (is_qn and next.pulse == .HIGH) {
                std.debug.print("\nHIGH to {s}: {d}", .{ next.from, i });
                try self.final_output_modules.?.append(i + 1);
                aoc.blockAskForNext();
            }

            if (self.final_output_modules != null and self.final_output_modules.?.items.len == 4) return true;

            // std.debug.print("\n{s} -{any}-> {s}", .{ next.from, next.pulse, next.to.name });
            try next.to.process(next.pulse, next.from, &transfers);
        }

        return low_pulse_to_rx;
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.StringHashMap(Node) {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var module_dict = std.StringHashMap(Node).init(allocator);

    var module_links = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer module_links.deinit();

    while (row_it.next()) |row| {
        var entry_it = std.mem.splitSequence(u8, row, "->");
        var module_name = entry_it.next().?;
        module_name = std.mem.trim(u8, module_name, " ");
        const modifier_char: u8 = module_name[0];

        var node_type: NodeType = .BROADCAST;
        switch (modifier_char) {
            '%' => {
                module_name = module_name[1..];
                node_type = .FLIP_FLOP;
            },
            '&' => {
                module_name = module_name[1..];
                node_type = .CONJUNCTION;
            },
            else => {},
        }

        ///// Modules
        const module = switch (node_type) {
            .CONJUNCTION => Node{
                .name = module_name,
                .module = .{ .CONJUNCTION = std.StringHashMap(Pulse).init(allocator) },
                .inputs = std.ArrayList(*Node).init(allocator),
                .outputs = std.ArrayList(*Node).init(allocator),
            },
            .FLIP_FLOP => Node{
                .name = module_name,
                .module = .{ .FLIP_FLOP = false },
                .inputs = std.ArrayList(*Node).init(allocator),
                .outputs = std.ArrayList(*Node).init(allocator),
            },
            .BROADCAST => Node{
                .name = module_name,
                .module = .{ .BROADCAST = true },
                .inputs = std.ArrayList(*Node).init(allocator),
                .outputs = std.ArrayList(*Node).init(allocator),
            },
            .OTHER => Node{
                .name = module_name,
                .module = .{ .OTHER = true },
                .inputs = std.ArrayList(*Node).init(allocator),
                .outputs = std.ArrayList(*Node).init(allocator),
            },
        };

        // try module_list.append(module);
        try module_dict.put(module_name, module);

        ///// Links
        const receiver_list_str = entry_it.next().?;
        var receiver_list_it = std.mem.tokenize(u8, receiver_list_str, ", ");
        var receivers = std.ArrayList([]const u8).init(allocator);
        while (receiver_list_it.next()) |receiver_name| {
            try receivers.append(receiver_name);
        }
        try module_links.put(module_name, receivers);
    }

    var receivers_it = module_links.valueIterator();
    while (receivers_it.next()) |receiver_modules| {
        for (receiver_modules.items) |receiver_name| {
            var found = false;
            var module_it = module_dict.valueIterator();
            while (module_it.next()) |module| {
                if (std.mem.eql(u8, receiver_name, module.name))
                    found = true;
            }
            if (!found) {
                const module = Node{
                    .name = receiver_name,
                    .module = .{ .OTHER = true },
                    .inputs = std.ArrayList(*Node).init(allocator),
                    .outputs = std.ArrayList(*Node).init(allocator),
                };
                try module_dict.put(receiver_name, module);
            }
        }
    }

    var module_it = module_dict.keyIterator();
    while (module_it.next()) |key| {
        if (module_dict.getPtr(key.*)) |module| {
            if (module_links.get(key.*)) |outputs| {
                for (outputs.items) |output| {
                    if (module_dict.getPtr(output)) |output_module| {
                        try module.addOutput(output_module);
                        try output_module.addInput(module);
                        if (output_module.module == .CONJUNCTION) {
                            try output_module.module.CONJUNCTION.put(module.name, .LOW);
                        }
                    }
                }
            }
        }
    }
    return module_dict;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var system = SystemState{
        .allocator = allocator,
        .module_dict = try parseInput(allocator, input),
    };
    std.debug.print("\n{any}", .{system});

    for (0..1000) |i| {
        std.debug.print("\n\n###### Button Press {d}", .{i});
        _ = try system.pressButton(i);
    }
    std.debug.print("\n{any}", .{system});
    std.debug.print("\n\nResult: {d}", .{system.high_pulses_sent * system.low_pulses_sent});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var system = SystemState{
        .allocator = allocator,
        .module_dict = try parseInput(allocator, input),
        .final_output_modules = std.ArrayList(u64).init(allocator),
    };

    if (system.module_dict.get("rx")) |rx_module| {
        std.debug.print("\n{any}:", .{rx_module});
        if (system.module_dict.get("th")) |th_module| {
            for (th_module.inputs.items) |th_input| {
                std.debug.print("\n   → {s} [{any}]", .{ th_input.name, th_input.module });
            }
        }
    }

    var i: usize = 0;
    while (true) : (i += 1) {
        std.debug.print("\n\n###### Button Press {d}", .{i});
        if (try system.pressButton(i)) break;
    }
    const solution = math.lcm(u64, system.final_output_modules.?.items);
    std.debug.print("\n{any}", .{system});
    std.debug.print("\n\nResult: {d}", .{solution});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    try aoc.runPart(arena_alloc, 2023, 20, .PUZZLE, part1);
    try aoc.runPart(arena_alloc, 2023, 20, .PUZZLE, part2);
}
