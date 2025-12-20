const std = @import("std");
const t = @import("../term.zig");

const Allocator = std.mem.Allocator;

pub const Map = struct {
    rows: usize,
    cols: usize,
    buffer: []u8,
    allocator: Allocator = undefined,

    pub fn init(allocator: Allocator, buffer: []const u8) !Map {
        if (std.mem.indexOf(u8, buffer, "\n")) |line_end| {
            const clean = std.mem.trimEnd(u8, buffer, "\n");
            return .{
                .allocator = allocator,
                .buffer = try std.mem.replaceOwned(u8, allocator, clean, "\n", ""),
                .cols = line_end,
                .rows = (clean.len - 1) / line_end,
            };
        }
        @panic("Failed to split input buffer!");
    }

    pub fn initEmpty(allocator: Allocator, cols: usize, rows: usize, fill: u8) !Map {
        const buffer = try allocator.alloc(u8, rows * cols);
        for (0..(rows * cols)) |i| buffer[i] = fill;
        return .{
            .allocator = allocator,
            .buffer = buffer,
            .cols = cols,
            .rows = rows,
        };
    }

    pub fn get(self: *const Map, x: usize, y: usize) u8 {
        return self.buffer[(y * self.cols) + x];
    }

    pub fn set(self: *const Map, x: usize, y: usize, v: u8) void {
        self.buffer[(y * self.cols) + x] = v;
    }

    pub fn format(self: Map, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Map {d} x {d}\n", .{ self.rows, self.cols });
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                try writer.print("{c}", .{self.get(x, y)});
            }
            try writer.print("\n", .{});
        }
    }

    pub fn deinit(self: Map) void {
        self.allocator.free(self.buffer);
    }

    pub fn animate(self: Map) void {
        std.debug.print(t.hide_cursor, .{});
        for (0..self.cols) |x| {
            for (0..self.rows - 1) |y| {
                std.debug.print(t.yx, .{ y, x });
                const v = self.get(x, y);
                switch (v) {
                    '|' => std.debug.print("{s}{c}{s}", .{ t.yellow, v, t.clear }),
                    '^' => std.debug.print("{s}{c}{s}", .{ t.red, v, t.clear }),
                    '.' => std.debug.print("{s}{c}{s}", .{ t.dark_gray, v, t.clear }),
                    else => std.debug.print("{s}{c}{s}", .{ t.blue, v, t.clear }),
                }
            }
        }
        // std.Thread.sleep(std.time.ns_per_ms * 60);
    }
};
