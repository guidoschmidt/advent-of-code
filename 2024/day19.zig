const std = @import("std");
const aoc = @import("aoc");
const t = @import("term");

const DAY: u8 = 19;
const Allocator = std.mem.Allocator;
const log = std.log;

const ParseResult = struct {
    patterns: [][]const u8,
    designs: [][]const u8,
    pattern_range: @Vector(2, usize),
};

fn parseInput(allocator: Allocator, input: []const u8) !ParseResult {
    var towel_patterns = std.ArrayList([]const u8).init(allocator);
    var designs = std.ArrayList([]const u8).init(allocator);

    const cleaned_input = std.mem.trimRight(u8, input, "\n");
    var it = std.mem.splitSequence(u8, cleaned_input, "\n");

    var min_pattern_len: usize = 10;
    var max_pattern_len: usize = 1;
    const patterns = it.next().?;
    var pattern_it = std.mem.splitSequence(u8, patterns, ", ");
    while (pattern_it.next()) |pattern| {
        if (pattern.len > max_pattern_len)
            max_pattern_len = pattern.len;
        if (pattern.len < min_pattern_len)
            min_pattern_len = pattern.len;
        try towel_patterns.append(pattern);
    }

    _ = it.next();
    while (it.next()) |design| {
        const cleaned = std.mem.trim(u8, design, " ");
        try designs.append(cleaned);
    }

    return ParseResult{
        .patterns = towel_patterns.items,
        .designs = designs.items,
        .pattern_range = .{ min_pattern_len, max_pattern_len },
    };
}

fn matchingPattern(start: usize, design: []const u8, patterns: *const [][]const u8) bool {
    if (start == design.len) return true;

    for (patterns.*) |pattern| {
        const end = start + pattern.len;
        if (end <= design.len and std.mem.eql(u8, design[start..end], pattern)) {
            if (matchingPattern(end, design, patterns)) {
                return true;
            }
        }
    }

    return false;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    const parsed = try parseInput(allocator, input);

    log.info("{s}PATTERNS:", .{t.blue});
    for (parsed.patterns) |pattern| {
        log.info("{s}", .{pattern});
    }

    log.info("{s}DESIGNS:", .{t.magenta});
    for (parsed.designs) |design| {
        log.info("{s}", .{design});
    }

    log.info("{s}Min/Max: [{d}]", .{ t.clear, parsed.pattern_range });

    var possible_count: usize = 0;
    for (0..parsed.designs.len) |d| {
        const design = parsed.designs[d];
        log.info("------\n      {s}{s}{s}", .{ t.yellow, design, t.clear });
        const possible = matchingPattern(0, design, &parsed.patterns);
        if (possible) possible_count += 1;
        log.info("{s} POSSIBLE?: {any}", .{ design, possible });
    }

    std.debug.print("\nResult: {d}", .{possible_count});
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    _ = allocator;
    _ = input;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try aoc.runPart(allocator, 2024, DAY, .PUZZLE, part1);
    //try aoc.runPart(allocator, 2024, DAY, .EXAMPLE, part2);
}
