const std = @import("std");
const fs = std.fs;
const http = std.http;

fn getAdventOfCodeCookieFromEnv(allocator: std.mem.Allocator) !?[]const u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    return env_map.get("AOC_COOKIE");
}

pub fn getPuzzleInputFromServer(allocator: std.mem.Allocator, year: u16, day: usize, file_path: []const u8) !void {
    if (std.fs.path.dirname(file_path)) |basepath| {
        fs.cwd().makeDir(basepath) catch {
            std.debug.print("\n{s} already exists. Continue...", .{basepath});
        };
    }

    // Get AOC_COOKIE from environment
    const cookie_from_env = try getAdventOfCodeCookieFromEnv(allocator);
    if (cookie_from_env == null) {
        std.log.err("\nPlease set AOC_COOKIE env variable", .{});
    }
    std.debug.print("\nAOC_COOKIE: {s}", .{cookie_from_env.?});

    // Build URL
    var buf: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&buf, "https://adventofcode.com/{d}/day/{d}/input", .{ year, day });

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();

    const req = try client.fetch(.{ .location = .{ .url = url }, .extra_headers = &.{.{
        .name = "cookie",
        .value = cookie_from_env.?,
    }}, .response_storage = .{
        .dynamic = &body,
    } });

    if (req.status == .ok) std.debug.print("Success", .{});
    std.debug.print("\n{s}", .{file_path});

    const new_file = try fs.cwd().createFile(file_path, .{});
    defer new_file.close();
    try new_file.writeAll(body.items);
}

pub fn getPuzzleInput(allocator: std.mem.Allocator, day: u8, year: u16) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "./aoc/input/{d}/day{d}.txt", .{ year, day });
    const file = fs.cwd().openFile(file_path, .{}) catch {
        try getPuzzleInputFromServer(allocator, year, day, file_path);
        const f = try fs.cwd().openFile(file_path, .{});
        const s = try f.stat();
        return f.readToEndAlloc(allocator, s.size);
    };
    const stat = try file.stat();
    if (stat.size == 0) {
        try getPuzzleInputFromServer(allocator, year, day, file_path);
    }
    return try file.readToEndAlloc(allocator, stat.size);
}

pub fn getExampleInput(allocator: std.mem.Allocator, day: u8, year: u16) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "./input/{d}/examples/day{d}.txt", .{ year, day });
    const file = try fs.cwd().openFile(file_path, .{});
    const stat = try file.stat();
    return try file.readToEndAlloc(allocator, stat.size);
}
