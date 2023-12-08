const std = @import("std");
const fs = std.fs;

var file: fs.File = undefined;
var buf: [32]u8 = undefined;

pub fn init(file_path: []const u8, width: u32, height: u32) !void {
    file = try fs.cwd().createFile(file_path, .{});
    _ = try file.write("P3\n");

    const ppm_size = try std.fmt.bufPrint(&buf, "{d} {d}\n255", .{ width, height });
    _ = try file.write(ppm_size);
}

pub fn write_rgb(r: u8, g: u8, b: u8) !void {
    const ppm_rgb = try std.fmt.bufPrint(&buf, "{d} {d} {d} ", .{ r, g, b });
    _ = try file.write(ppm_rgb);
}
