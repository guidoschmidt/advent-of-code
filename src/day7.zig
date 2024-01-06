const std = @import("std");
const common = @import("./common.zig");
const puzzle_input = @import("./puzzle_input.zig");
const sw = @import("./stopwatch.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Rating = enum(u8) {
    FIVE_OF_A_KIND = 7,
    FOUR_OF_A_KIND = 6,
    FULL_HOUSE = 5,
    THREE_OF_A_KIND = 4,
    TWO_PAIR = 3,
    ONE_PAIR = 2,
    HIGH_CARD = 1,
    NONE = 0,
};

const Card = struct {
    hand: []const u8,
    rating: Rating,
    bid: u32,
};

fn cardValueFromLetter(c: u8) u8 {
    return switch (c) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'J' => 11,
        'T' => 10,
        else => std.fmt.charToDigit(c, 10) catch 0 
    };
}

fn calculateRankType(hand: *const [5]u8) !Rating {
    var uniques = std.AutoHashMap(u8, u8).init(allocator);
    try uniques.put(hand[0], 1);
    for (1..hand.len) |i| {
        if (uniques.contains(hand[i])) {
            uniques.getPtr(hand[i]).?.* += 1;
            continue;
        }
        try uniques.put(hand[i], 1);
    }
    var value_it = uniques.valueIterator();
    var rating: Rating = Rating.NONE;
    switch (uniques.count()) {
        // Five of a kind
        1 => rating = Rating.FIVE_OF_A_KIND,
        2 => {
            const a = value_it.next().?.*;
            const b = value_it.next().?.*;
            if (a == 4 and b == 1 or
                b == 4 and a == 1)
            {
                rating = Rating.FOUR_OF_A_KIND;
            }
            if (a == 3 and b == 2 or
                b == 3 and a == 2)
            {
                rating = Rating.FULL_HOUSE;
            }
        },
        3 => {
            const a = value_it.next().?.*;
            const b = value_it.next().?.*;
            const c = value_it.next().?.*;
            if (a == 3 or b == 3 or c == 3) {
                rating = Rating.THREE_OF_A_KIND;
            }
            if (a == 2 or b == 2 or c == 2) {
                rating = Rating.TWO_PAIR;
            }
        },
        4 => rating = Rating.ONE_PAIR,
        5 => rating = Rating.HIGH_CARD,
        else => rating = Rating.NONE,
    }
    // std.debug.print("\n{d} Rating: {any} [{s}]", .{ uniques.count(), rating, hand });
    return rating;
}

fn secondOrderingRule(hand_a: []const u8, hand_b: []const u8) bool {
    var hand_a_wins = false;
    for(hand_a, hand_b) |a,b| {
        const val_a = cardValueFromLetter(a);
        const val_b = cardValueFromLetter(b);
        // std.debug.print("\n{c} {c}: {d} < {d}", .{ a, b, val_a, val_b });
        if (a == b) continue;
        hand_a_wins = val_b > val_a;
        break;
    }
    return hand_a_wins;
}

fn part1(input: []const u8) void {
    var cards = std.ArrayList(Card).init(allocator);
    var row_it = std.mem.tokenize(u8, input, "\n");
    while (row_it.next()) |row| {
        var entry_it = std.mem.split(u8, row, " ");
        const hand = entry_it.next().?;
        const rating = calculateRankType(@ptrCast(hand.ptr)) catch Rating.NONE;
        const bid_str = entry_it.next().?;
        const bid = std.fmt.parseInt(u32, bid_str, 10) catch 0;
        cards.append(Card{ .bid = bid, .rating = rating, .hand = hand }) catch {
            std.log.err("\nCould not append Card to cards", .{});
        };
    }
    std.mem.sort(Card, cards.items, {}, comptime struct {
        pub fn f(_: void, a: Card, b: Card) bool {
            const rating_a = @intFromEnum(a.rating);
            const rating_b = @intFromEnum(b.rating);
            if (rating_a == rating_b)
                return secondOrderingRule(a.hand, b.hand);
            return rating_a < rating_b;
        }
    }.f);
    var result: u64 = 0;
    var idx: u32 = 1;
    for(cards.items) |c| {
        std.debug.print("\n[{s}] → {any} {d:>10} * {d}", .{ c.hand, c.rating, c.bid, idx });
        result += c.bid * idx;
        idx += 1;
    }
    std.debug.print("\n{d}", .{ result });
}

fn part2(input: []const u8) void {
    _ = input;
}

pub fn main() !void {
    try common.runDay(allocator, 7, part1, part2);
}
