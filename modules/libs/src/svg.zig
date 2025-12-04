const std = @import("std");
const fs = std.fs;

var file: fs.File = undefined;
var buf: [128]u8 = undefined;

pub fn init(file_path: []const u8, width: i128, height: i128, min_x: i128, max_x: i128, min_y: i128, max_y: i128) !void {
    _ = max_y;
    _ = min_y;
    _ = max_x;
    _ = min_x;
    file = try fs.cwd().createFile(file_path, .{});
    const margin_x: i128 = @intFromFloat(@as(f32, @floatFromInt(width)) * 0.1);
    _ = margin_x;
    const margin_y: i128 = @intFromFloat(@as(f32, @floatFromInt(height)) * 0.1);
    _ = margin_y;
    // const svg_el = try std.fmt.bufPrint(&buf, "<svg viewBox=\"{d} {d} {d} {d}\" width=\"{d}\" height=\"{d}\" xmlns=\"http://www.w3.org/2000/svg\">",
    //                                     .{ -margin_x, -margin_y, width + 2 * margin_x, height + 2 * margin_y, width, height });
    const svg_el = try std.fmt.bufPrint(&buf, "<svg width=\"{d}\" height=\"{d}\" xmlns=\"http://www.w3.org/2000/svg\">",
                                        .{ width, height });
    _ = try file.write(svg_el);
}

pub fn addLine(x1: i128, y1: i128, x2: i128, y2: i128) !void {
    const line_el = try std.fmt.bufPrint(&buf, "<line x1=\"{d}\" y1=\"{d}\" x2=\"{d}\" y2=\"{d}\" style=\"stroke:black;stroke-width:10\" />", .{ x1, y1, x2, y2 });
    _ = try file.write(line_el);
}

pub fn addCirc(x: i128, y: i128) !void {
    const line_el = try std.fmt.bufPrint(&buf, "<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"black\" />", .{ x, y, 10 });
    _ = try file.write(line_el);
}

pub fn startPolygon() !void {
    _ = try file.write("<polygon points=\"");
}

pub fn addPolygonPoint(x: i128, y: i128) !void {
    const point = try std.fmt.bufPrint(&buf, "{d},{d} ", .{ x, y });
    _ = try file.write(point);
}

pub fn endPolygon() !void {
    _ = try file.write("\" fill=\"black\" />");
}

pub fn close() !void {
    _ = try file.write("</svg>");
    file.close();
}
