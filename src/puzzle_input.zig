const std = @import("std");
const http = std.http;

pub fn getPuzzleInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
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
    return try rdr.readAllAlloc(allocator, 4006);
}
