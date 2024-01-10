const std = @import("std");
const fs = std.fs;
const http = std.http;

fn getAdventOfCodeCookieFromEnv(allocator: std.mem.Allocator) !?[]const u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    return env_map.get("AOC_COOKIE");
}

pub fn getPuzzleInputFromServer(allocator: std.mem.Allocator, day: u8, file_path: []const u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const new_file = try fs.cwd().createFile(file_path, .{});
    const url = try std.fmt.bufPrint(&buf, "https://adventofcode.com/2023/day/{d}/input", .{ day });
    var headers = http.Headers{ .allocator = allocator };
    const cookie_from_env = try getAdventOfCodeCookieFromEnv(allocator);
    if (cookie_from_env == null) {
        std.log.err("\nPlease set AOC_COOKIE env variable", .{});
        return "";
    }
    //std.debug.print("\n{s}", .{ cookie_from_env.? });
    try headers.append("Cookie", cookie_from_env.?);
    defer headers.deinit();

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);
    var req = try client.request(.GET, uri, headers, .{});
    defer req.deinit();

    try req.start();
    try req.wait();

    var rdr = req.reader();
    const body = try rdr.readAllAlloc(allocator, 4096 * 10);
    try new_file.writeAll(body);
    return body;
}

pub fn getPuzzleInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "src/data/day{d}.txt", .{ day });
    const file = fs.cwd().openFile(file_path, .{}) catch {
        return getPuzzleInputFromServer(allocator, day, file_path);   
    };
    const stat = try file.stat();
    if (stat.size == 0) {
        return getPuzzleInputFromServer(allocator, day, file_path);
    }
    return try file.readToEndAlloc(allocator, stat.size);
}

pub fn getPuzzleTestInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "src/data/day{d}-test.txt", .{ day });
    const file = try fs.cwd().openFile(file_path, .{});
    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}
