const std = @import("std");
const fs = std.fs;

var file: fs.File = undefined;
var buf: [32]u8 = undefined;

pub fn init(file_path: []const u8, width: usize, height: usize) !void {
    file = try fs.cwd().createFile(file_path, .{});
    _ = try file.write("P2\n");

    const ppm_size = try std.fmt.bufPrint(&buf, "{d} {d}\n255", .{ height, width });
    _ = try file.write(ppm_size);
}

pub fn writeValue(value: []const u8) !void {
    _ = try file.write(value);
}

pub fn nextRow() !void {
    _ = try file.write("\n");
}

pub fn write(map: *[][]u8) !void {
    for(0..map.len) |x| {
        const row = map.*[x];
        _ = try file.write("\n");
        for(0..row.len) |y| {
            const v = map.*[x][y];
            const g: u8 = if (v == '.') 1 else 255;
            const o = try std.fmt.bufPrint(&buf, "{d} ", .{ g });
            _ = try file.write(o);
        }
    }
    try file.sync();
    file.close();
}
