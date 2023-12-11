const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const data = @embedFile("data/day4.txt");

pub fn main() !void {
    var cards_it = std.mem.tokenize(u8, data, "\n");

    var total_points: u32 = 0;

    while(cards_it.next()) |card| {
        var card_it = std.mem.split(u8, card, ":");
        const card_str = card_it.next();
        var num_list_it = std.mem.split(u8, card_it.next().?, "|");
        var winning_num_list_it = std.mem.tokenize(u8, num_list_it.next().?, " ");
        var player_num_list_it = std.mem.tokenize(u8, num_list_it.next().?, " ");
        std.debug.print("\n- {s} ---\n", .{ card_str.? });

        var winning_numbers = std.ArrayList(u32).init(allocator);
        var player_numbers = std.ArrayList(u32).init(allocator);

        while(winning_num_list_it.next()) |winning_number_str| {
            const winning_number = try std.fmt.parseInt(u32, winning_number_str, 10);
            std.debug.print("{d}, ", .{ winning_number });
            try winning_numbers.append(winning_number);
        }
        while(player_num_list_it.next()) |player_number_str| {
            const player_number = try std.fmt.parseInt(u32, player_number_str, 10);
            std.debug.print("{d}, ", .{ player_number });
            try player_numbers.append(player_number);
        }

        var points: u32 = 0;

        for (player_numbers.items) |pn| {
            for (winning_numbers.items) |wn| {
                if (pn == wn) {
                    if (points == 0) {
                        points = 1;
                    }
                    else {
                        points *= 2;
                    }
                }
            }
        }
        total_points += points;
    }

    std.debug.print("\nTotal Points: {d}", .{ total_points });
}
