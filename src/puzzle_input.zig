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
    // var headers = http.Headers{ .allocator = allocator };
    const cookie_from_env = try getAdventOfCodeCookieFromEnv(allocator);
    if (cookie_from_env == null) {
        std.log.err("\nPlease set AOC_COOKIE env variable", .{});
        return "";
    }
    std.debug.print("\nAOC_COOKIE: {s}", .{ cookie_from_env.? });
    // try headers.append("Cookie", cookie_from_env.?);
    // defer headers.deinit();

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();

    const req = try client.fetch(.{
        .location = .{ .url = url },
        .extra_headers = &.{
            .{ .name = "Cookie", .value = cookie_from_env.? }
        },
        .response_storage = .{
            .dynamic = &body,
        }
    });
    if (req.status == .ok) {
        std.debug.print("\nSuccess", .{});
    }

    try new_file.writeAll(body.items);
    return body.items;
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

pub fn getExampleInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "src/data/day{d}-example.txt", .{ day });
    const file = try fs.cwd().openFile(file_path, .{});
    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}
