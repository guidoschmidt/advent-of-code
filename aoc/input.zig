const std = @import("std");
const fs = std.fs;
const http = std.http;

fn getAdventOfCodeCookieFromEnv(allocator: std.mem.Allocator) !?[]const u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    return env_map.get("AOC_COOKIE");
}

pub fn getPuzzleInputFromServer(allocator: std.mem.Allocator, year: u16, day: usize, file_path: []const u8) !void {
    var buf: [128]u8 = undefined;
    if (std.fs.path.dirname(file_path)) |basepath| {
        fs.cwd().makeDir(basepath) catch {
            std.debug.print("\n{s} already exists. Continue...", .{basepath});
        };
    }
    const url = try std.fmt.bufPrint(&buf, "https://adventofcode.com/{d}/day/{d}/input", .{ year, day });
    // var headers = http.Headers{ .allocator = allocator };
    const cookie_from_env = try getAdventOfCodeCookieFromEnv(allocator);
    if (cookie_from_env == null) {
        std.log.err("\nPlease set AOC_COOKIE env variable", .{});
        return;
    }
    std.debug.print("\nAOC_COOKIE: {s}", .{cookie_from_env.?});

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();

    const req = try client.fetch(.{ .location = .{ .url = url }, .extra_headers = &.{.{ .name = "Cookie", .value = cookie_from_env.? }}, .response_storage = .{
        .dynamic = &body,
    } });
    if (req.status == .ok) {
        std.debug.print("\nSuccess", .{});
    }
    std.debug.print("{s}", .{body.items});
    if (std.mem.containsAtLeast(u8, body.items, 1, "Please log in")) {
        std.debug.print("Please make sure AOC_COOKIE is set!", .{});
        return;
    }

    const new_file = try fs.cwd().createFile(file_path, .{});
    try new_file.writeAll(body.items);
}

pub fn getPuzzleInput(comptime day: u8, comptime year: u16) ![]const u8 {
    var compbuf: [128]u8 = undefined;
    const path = try std.fmt.bufPrint(&compbuf, "./input/{d}/day{d}.txt", .{ year, day });
    return @embedFile(path);
}

pub fn getExampleInput(comptime day: u8, comptime year: u16) ![]const u8 {
    var buf: [128]u8 = undefined;
    const file_path = try std.fmt.bufPrint(&buf, "./input/{d}/examples/day{d}.txt", .{ year, day });
    return @embedFile(file_path);
}
