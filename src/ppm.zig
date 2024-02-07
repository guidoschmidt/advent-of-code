const std = @import("std");
const fs = std.fs;

var file: fs.File = undefined;
var buf: [32]u8 = undefined;

pub fn init(file_path: []const u8, width: usize, height: usize) !void {
    file = try fs.cwd().createFile(file_path, .{});
    _ = try file.write("P1\n");

    const ppm_size = try std.fmt.bufPrint(&buf, "{d} {d}", .{ height, width });
    _ = try file.write(ppm_size);
}

pub fn write(map: *[][]u8) !void {
    for(0..map.len) |x| {
        const row = map.*[x];
        _ = try file.write("\n");
        for(0..row.len) |y| {
            const v = map.*[x][y];
            const g: u8 = if (v == '.') 1 else 0;
            const o = try std.fmt.bufPrint(&buf, "{d} ", .{ g });
            _ = try file.write(o);
        }
    } 
}

// pub fn write_rgb(r: u8, g: u8, b: u8) !void {
//     const ppm_rgb = try std.fmt.bufPrint(&buf, "{d} {d} {d} ", .{ r, g, b });
//     _ = try file.write(ppm_rgb);
// }
