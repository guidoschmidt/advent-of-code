const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 9;
const Allocator = std.mem.Allocator;
const log = std.log;

const BlockType = enum { FILE, SPACE };

const Block = struct {
    val: isize,
    type: BlockType,
    len: usize,

    pub fn size(self: Block) usize {
        return self.len;
    }

    pub fn format(self: Block, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (0..self.len) |_| {
            switch (self.type) {
                .SPACE => try writer.print(".", .{}),
                .FILE => try writer.print("{s}{s}{d}{s}", .{ t.bg_white, t.black, self.val, t.clear }),
            }
        }
    }
};

fn parseInput(allocator: Allocator, input: []const u8) !std.ArrayList(usize) {
    var disk_map = std.ArrayList(usize).init(allocator);
    for (input) |c| {
        if (c == '\n') break;
        const num = try std.fmt.charToDigit(c, 10);
        try disk_map.append(@intCast(num));
    }
    return disk_map;
}

fn printMap(comptime T: type, map: []const T) void {
    for (map) |d| {
        if (d == -1) {
            std.debug.print("{c}", .{'.'});
        } else {
            std.debug.print("{d}", .{d});
        }
    }
    std.debug.print("\n", .{});
}

fn printBlockMap(map: []const Block, file_ptr: usize, space_ptr: usize) void {
    std.debug.print("\n", .{});
    for (map) |b| {
        std.debug.print("{s}", .{b});
    }
    std.debug.print("\n", .{});
    for (0..map.len) |i| {
        const block = map[i];
        const block_len = block.size();
        for (0..block_len) |j| {
            if (j == 0 and i == file_ptr) {
                std.debug.print("{s}↑{s}", .{ t.green, t.clear });
                continue;
            }
            if (j == 0 and i == space_ptr) {
                std.debug.print("{s}↑{s}", .{ t.red, t.clear });
                continue;
            }
            std.debug.print(" ", .{});
        }
    }
}

fn calcBlockChecksum(block_map: []Block) !usize {
    var cksm: usize = 0;
    var x: usize = 0;
    for (0..block_map.len) |i| {
        const block = block_map[i];
        for (0..block.len) |_| {
            // std.debug.print("\n{d}: {d}", .{ x, block.val });
            if (block.val != -1) {
                cksm += x * @as(usize, @intCast(block.val));
            }
            x += 1;
        }
    }
    return cksm;
}

fn calcChecksum(block_map: []const isize) !usize {
    var cksm: usize = 0;
    for (1..block_map.len) |i| {
        if (block_map[i] == -1) continue;
        const num: usize = @intCast(block_map[i]);
        cksm += i * num;
    }
    return cksm;
}

fn moveFileBlocks(allocator: Allocator, disk_map: []const usize) !void {
    var block_map = std.ArrayList(isize).init(allocator);
    var idx: usize = 0;
    for (0..disk_map.len) |i| {
        const count = disk_map[i];
        if (@mod(i, 2) == 1) {
            for (0..count) |j| {
                log.info("{d} -> .", .{j});
                try block_map.append(-1);
            }
            idx += 1;
        } else {
            for (0..count) |j| {
                log.info("{d} -> {d}", .{ j, idx });
                try block_map.append(@intCast(idx));
            }
        }
    }

    printMap(isize, block_map.items);

    var s: usize = 0;
    var e: usize = block_map.items.len - 1;
    while (s < e) {
        if (block_map.items[s] == -1) {
            std.mem.swap(isize, &block_map.items[s], &block_map.items[e]);
            e -= 1;
        } else {
            s += 1;
        }
    }

    printMap(isize, block_map.items);

    std.debug.print("\nDisk Map size: {d}", .{disk_map.len});
    std.debug.print("\nBlock Map size: {d}", .{block_map.items.len});

    const cksm = try calcChecksum(block_map.items);
    std.debug.print("\n\nResult: {d}", .{cksm});
}

fn moveFiles(allocator: Allocator, disk_map: []const usize) !void {
    var block_map = std.ArrayList(Block).init(allocator);
    var idx: usize = 0;
    for (0..disk_map.len) |i| {
        const count = disk_map[i];
        if (@mod(i, 2) == 1) {
            try block_map.append(Block{ .len = count, .type = .SPACE, .val = -1 });
            idx += 1;
        } else {
            try block_map.append(Block{ .len = count, .type = .FILE, .val = @intCast(idx) });
        }
    }

    var file_block_idx: usize = block_map.items.len;
    while (file_block_idx > 0) {
        file_block_idx -|= 1;
        const file_block = block_map.items[file_block_idx];
        if (file_block.type == .SPACE) continue;

        // printBlockMap(block_map.items, file_block_idx, 0);
        for (0..file_block_idx) |space_block_idx| {
            const space_block = block_map.items[space_block_idx];
            if (space_block.type == .FILE) continue;

            if (space_block.size() >= file_block.size()) {
                const diff = @abs(space_block.size() - file_block.size());
                // std.debug.print("\n{d} | {d} [{d}]", .{ space_block.size(), file_block.size(), diff });

                std.mem.swap(Block, &block_map.items[space_block_idx], &block_map.items[file_block_idx]);
                block_map.items[file_block_idx].len = file_block.size();
                try block_map.insert(space_block_idx + 1, Block{ .len = diff, .type = .SPACE, .val = -1 });

                break;
            }
            // printBlockMap(block_map.items, file_block_idx, space_block_idx);
            // aoc.blockAskForNext();
        }
    }

    const cksm = try calcBlockChecksum(block_map.items);
    std.debug.print("\n\nResult: {d}", .{cksm});
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const disk_map = try parseInput(allocator, input);
    try moveFileBlocks(allocator, disk_map.items);
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    const disk_map = try parseInput(allocator, input);
    try moveFiles(allocator, disk_map.items);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part2);
}
