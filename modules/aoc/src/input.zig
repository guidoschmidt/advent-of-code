const std = @import("std");
const types = @import("types.zig");

const fs = std.fs;
const http = std.http;

fn getAdventOfCodeCookieFromEnv(allocator: std.mem.Allocator) !?[]const u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    return env_map.get("AOC_COOKIE");
}

pub fn getPuzzleInputFromServer(
    allocator: std.mem.Allocator,
    year: types.Year,
    day: types.Day,
    puzzle_file_path: ?[]const u8,
) ![]const u8 {
    std.debug.print("🎄 Fetching puzzle input ...\n", .{});

    // Get AOC_COOKIE from environment
    const cookie = try getAdventOfCodeCookieFromEnv(allocator);
    if (cookie == null) {
        const msg = "⚠ Please set AOC_COOKIE env variable1";
        std.log.err(msg, .{});
        return msg;
    }
    std.debug.print("🍪 AOC_COOKIE:\n{s}\n", .{cookie.?});

    // Build URL string
    var buf: [128]u8 = undefined;
    const url = try std.fmt.bufPrint(&buf, "https://adventofcode.com/{d}/day/{d}/input", .{
        year,
        day,
    });

    // Init HTT client
    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    // Body writer
    var response: std.Io.Writer.Allocating = .init(allocator);
    defer response.deinit();

    // Perform HTTP call
    _ = try client.fetch(.{
        .location = .{ .url = url },
        .extra_headers = &.{.{
            .name = "cookie",
            .value = cookie.?,
        }},
        .method = .GET,
        .response_writer = &response.writer,
    });

    const puzzle_input = try response.toOwnedSlice();

    // Write to file
    if (puzzle_file_path) |filepath| {
        var puzzle_file = try std.fs.cwd().createFile(filepath, .{});
        defer puzzle_file.close();
        try puzzle_file.writeAll(puzzle_input);
    }

    return puzzle_input;
}

pub fn getPuzzleInput(
    allocator: std.mem.Allocator,
    cwd: []const u8,
    day: types.Day,
) ![]const u8 {
    var day_buf: [16]u8 = undefined;

    const file_path = try std.fs.path.join(allocator, &.{
        cwd,
        "src",
        "input",
        "puzzle",
        try std.fmt.bufPrint(&day_buf, "day{d:0>2}.txt", .{day}),
    });
    std.debug.print("{s}\n", .{file_path});

    const file = try fs.cwd().openFile(file_path, .{});
    // catch {
    //     // try getPuzzleInputFromServer(allocator, year, day, file_path);
    //     // const f = try fs.cwd().openFile(file_path, .{});
    //     // const s = try f.stat();
    //     // var buffer: [1]u8 = undefined;
    //     // var reader = f.reader(&buffer);
    //     // return reader.interface.readAlloc(allocator, s.size);
    // };
    const stat = try file.stat();
    std.debug.print("File size: {d}", .{stat.size});
    if (stat.size == 0) {
        // try getPuzzleInputFromServer(allocator, year, day, file_path);
    }

    var buffer: [1]u8 = undefined;
    var reader = file.reader(&buffer);
    return reader.interface.readAlloc(allocator, stat.size);
}

pub fn getExampleInput(
    allocator: std.mem.Allocator,
    cwd: []const u8,
    day: types.Day,
) ![]const u8 {
    var day_buf: [16]u8 = undefined;
    const file_path = try std.fs.path.join(allocator, &.{
        cwd,
        "src",
        "input",
        "example",
        // try std.fmt.bufPrint(&year_buf, "{d}", .{year}),
        // "examples",
        try std.fmt.bufPrint(&day_buf, "day{d:0>2}.txt", .{day}),
    });
    errdefer allocator.free(file_path);
    const file = try fs.cwd().openFile(file_path, .{});
    defer file.close();
    const stat = try file.stat();
    var buffer: [1]u8 = undefined;
    var reader = file.reader(&buffer);
    return reader.interface.readAlloc(allocator, stat.size);
}
