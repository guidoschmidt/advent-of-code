const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 17;
const Allocator = std.mem.Allocator;
const log = std.log;

const Instruction = enum(u3) {
    ADV = 0,
    BXL = 1,
    BST = 2,
    JNZ = 3,
    BXC = 4,
    OUT = 5,
    BDV = 6,
    CDV = 7,
};

const Register = enum(u2) { A = 0, B = 1, C = 2 };

const Machine = struct {
    memory: [3]usize = .{ 0, 0, 0 },
    program: []const u8 = undefined,
    instr_ptr: usize = 0,
    output: std.ArrayList(usize) = undefined,

    pub fn init(allocator: Allocator) Machine {
        var instance = Machine{};
        instance.output = std.ArrayList(usize).init(allocator);
        return instance;
    }

    pub fn setProgram(self: *Machine, program_code: []const u8) void {
        self.program = program_code;
    }

    pub fn setMemory(self: *Machine, register: Register, val: usize) void {
        self.memory[@intFromEnum(register)] = val;
    }

    pub fn retrieveComboOp(self: *Machine, op: usize) usize {
        return switch (op) {
            0, 1, 2, 3 => op,
            4 => self.memory[@intFromEnum(Register.A)],
            5 => self.memory[@intFromEnum(Register.B)],
            6 => self.memory[@intFromEnum(Register.C)],
            else => unreachable,
        };
    }

    pub fn format(self: Machine, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("\n{s}MEMORY:\nA: {d}\nB: {d}\nC: {d}{s}", .{ t.cyan, self.memory[0], self.memory[1], self.memory[2], t.clear });
        try writer.print("\n{s}PROGRAM:\n", .{t.yellow});
        for (self.program) |p| {
            try writer.print("{d},", .{p});
        }
        try writer.print("{s}\n", .{t.clear});
        for (0..self.instr_ptr) |_| {
            try writer.print("  ", .{});
        }
        try writer.print("{s}↑ {s}", .{ t.red, t.clear });
        try writer.print("\n{s}OUTPUT: ", .{t.green});
        for (0..self.output.items.len) |i| {
            try writer.print("{d}", .{self.output.items[i]});
            if (self.output.items.len > 1 and i < self.output.items.len - 1)
                try writer.print(",", .{});
        }
        try writer.print("{s}\n\n", .{t.clear});
    }

    pub fn reverseEngineer(self: *Machine) !void {
        log.info("{any}", .{self});
        if (self.instr_ptr >= self.program.len - 1) {
            return;
        }

        const instruction: Instruction = @enumFromInt(self.program[self.instr_ptr]);
        const operand: usize = self.program[self.instr_ptr + 1];
        log.info("> {any}([{d}])", .{ instruction, operand });
        try self.reverseInstr(instruction, operand);

        aoc.blockAskForNext();
        try self.reverseEngineer();
    }

    pub fn run(self: *Machine) !void {
        log.info("{any}", .{self});
        if (self.instr_ptr >= self.program.len - 1) {
            return;
        }

        const instruction: Instruction = @enumFromInt(self.program[self.instr_ptr]);
        const operand: usize = self.program[self.instr_ptr + 1];
        log.info("> {any}({d})", .{ instruction, operand });
        try self.execInstr(instruction, operand);

        // aoc.blockAskForNext();

        try self.run();
    }

    pub fn reverseInstr(self: *Machine, instr: Instruction, op: usize) !void {
        switch (instr) {
            .ADV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.A)] = numerator / denominator;
                self.instr_ptr += 2;
            },
            .BXL => {
                self.memory[@intFromEnum(Register.B)] = self.memory[@intFromEnum(Register.B)] ^ op;
                self.instr_ptr += 2;
            },
            .BST => {
                const combo_op = self.retrieveComboOp(op);
                self.memory[@intFromEnum(Register.B)] = @mod(combo_op, 8);
                self.instr_ptr += 2;
            },
            .JNZ => {
                if (self.memory[@intFromEnum(Register.A)] == 0) {
                    self.instr_ptr += 2;
                    return;
                }
                self.instr_ptr = op;
            },
            .BXC => {
                self.memory[@intFromEnum(Register.B)] = self.memory[@intFromEnum(Register.B)] ^ self.memory[@intFromEnum(Register.C)];
                self.instr_ptr += 2;
            },
            .OUT => {
                const combo_op = self.retrieveComboOp(op);
                const result = @mod(combo_op, 8);
                try self.output.append(result);
                self.instr_ptr += 2;
            },
            .BDV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.B)] = numerator / denominator;
                self.instr_ptr += 2;
            },
            .CDV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.C)] = numerator / denominator;
                self.instr_ptr += 2;
            },
        }
    }

    pub fn execInstr(self: *Machine, instr: Instruction, op: usize) !void {
        switch (instr) {
            .ADV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.A)] = numerator / denominator;
                self.instr_ptr += 2;
            },
            .BXL => {
                self.memory[@intFromEnum(Register.B)] = self.memory[@intFromEnum(Register.B)] ^ op;
                self.instr_ptr += 2;
            },
            .BST => {
                const combo_op = self.retrieveComboOp(op);
                self.memory[@intFromEnum(Register.B)] = @mod(combo_op, 8);
                self.instr_ptr += 2;
            },
            .JNZ => {
                if (self.memory[@intFromEnum(Register.A)] == 0) {
                    self.instr_ptr += 2;
                    return;
                }
                self.instr_ptr = op;
            },
            .BXC => {
                self.memory[@intFromEnum(Register.B)] = self.memory[@intFromEnum(Register.B)] ^ self.memory[@intFromEnum(Register.C)];
                self.instr_ptr += 2;
            },
            .OUT => {
                const combo_op = self.retrieveComboOp(op);
                const result = @mod(combo_op, 8);
                try self.output.append(result);
                self.instr_ptr += 2;
            },
            .BDV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.B)] = numerator / denominator;
                self.instr_ptr += 2;
            },
            .CDV => {
                const combo_op = self.retrieveComboOp(op);
                const numerator = self.memory[@intFromEnum(Register.A)];
                const denominator = std.math.pow(usize, 2, combo_op);
                self.memory[@intFromEnum(Register.C)] = numerator / denominator;
                self.instr_ptr += 2;
            },
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !Machine {
    var machine = Machine.init(allocator);

    const trimmed = std.mem.trimRight(u8, input, "\n");
    var parts_it = std.mem.splitSequence(u8, trimmed, "\n\n");

    // Registers
    const registers_input = parts_it.next().?;
    var registers_it = std.mem.splitSequence(u8, registers_input, "\n");
    while (registers_it.next()) |r| {
        const clean_register_input = try std.mem.replaceOwned(u8, allocator, r, "Register ", "");
        const label = clean_register_input[0];
        const value_str = clean_register_input[3..];
        const value = try std.fmt.parseInt(usize, std.mem.trimRight(u8, value_str, "\n"), 10);

        switch (label) {
            'A' => machine.setMemory(.A, value),
            'B' => machine.setMemory(.B, value),
            'C' => machine.setMemory(.C, value),
            else => {},
        }
    }

    // Program
    const program_input = parts_it.next().?;
    const clean_program_input = try std.mem.replaceOwned(u8, allocator, program_input, "Program: ", "");
    const program_code: []u8 = try allocator.alloc(u8, clean_program_input.len / 2 + 1);
    var program_it = std.mem.splitSequence(u8, clean_program_input, ",");
    var idx: u8 = 0;
    while (program_it.next()) |p| : (idx += 1) {
        const n = try std.fmt.parseInt(u8, p, 10);
        program_code[idx] = n;
    }
    machine.setProgram(program_code);

    return machine;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var machine = try parseInput(allocator, input);
    try machine.run();
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var machine = try parseInput(allocator, input);
    try machine.reverseEngineer();
}

test "reverse bitwise XOR" {
    const in: usize = 10;
    const op: usize = 9;
    var result = in ^ op;
    try std.testing.expectEqual(@as(usize, 3), result);

    result = result ^ op;
    try std.testing.expectEqual(@as(usize, 10), result);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
