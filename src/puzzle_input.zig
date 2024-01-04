const std = @import("std");
const fs = std.fs;
const http = std.http;

pub fn getPuzzleInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "src/data/day{d}.txt", .{ day });
    const file = fs.cwd().openFile(file_path, .{}) catch {
        const new_file = try fs.cwd().createFile(file_path, .{});
        const url = try std.fmt.bufPrint(&buf, "https://adventofcode.com/2023/day/{d}/input", .{ day });
        var headers = http.Headers{ .allocator = allocator };
        try headers.append("Cookie", "***REMOVED***");
        defer headers.deinit();

        var client = http.Client{ .allocator = allocator };
        defer client.deinit();

        const uri = try std.Uri.parse(url);
        var req = try client.request(.GET, uri, headers, .{});
        defer req.deinit();

        try req.start();
        try req.wait();

        var rdr = req.reader();
        const body = try rdr.readAllAlloc(allocator, 4096);
        try new_file.writeAll(body);
        return body;
    };
    var stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}

pub fn getPuzzleTestInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "src/data/day{d}-test.txt", .{ day });
    const file = try fs.cwd().openFile(file_path, .{});
    var stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}
