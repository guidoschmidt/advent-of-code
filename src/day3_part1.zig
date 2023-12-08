const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const data = @embedFile("data/day3.txt");
    const clean_data = try allocator.alloc(u8, data.len);
    _ = std.mem.replace(u8, data, "\n", "", clean_data);

    var row_it = std.mem.tokenize(u8, data, "\n");
    const first_row = row_it.next().?;

    const col_count = first_row.len;
    const row_count = row_it.buffer.len / col_count;

    std.debug.print("\nSize: {d} x {d}\n{d}", .{ col_count, row_count, data.len });

    var sum: u32 = 0;

    for(0..col_count) |y| {
        var numbers = std.ArrayList(u8).init(allocator);
        var is_part_number = false;
        std.debug.print("\n", .{});
        for(0..row_count) |x| {
            const idx =  y * col_count + x;
            // std.debug.print("{c}", .{ clean_data[idx] });

            const char = clean_data[idx];

            const digit = std.fmt.charToDigit(char, 10) catch {
                // Not a digit anymore
                if (numbers.items.len == 0) continue;
                    var number: u32 = 0;
                    for(0..numbers.items.len) |i| {
                        const exp = std.math.pow(u32, 10, @intCast(i));
                        number += numbers.items[numbers.items.len - 1 - i] * exp;
                    }
                std.debug.print("\nFound number: {d} {any}", .{ number, is_part_number });
                if (is_part_number) {
                    sum += number;
                }
                numbers.clearAndFree();
                is_part_number = false;
                continue;
            };

            for(0..3) |xo| {
                for(0..3) |yo| {
                    const y_o: i16 = @as(i16, @intCast(yo)) - 1;
                    const x_o: i16 = @as(i16, @intCast(xo)) - 1;
                    if (x_o == 0 and y_o == 0) continue;
                    const idx_off: i16 = (@as(i16, @intCast(y)) + x_o) *
                        @as(i16, @intCast(col_count)) +
                        (@as(i16, @intCast(x)) + y_o);
                    const char_around = clean_data[@min(@max(idx_off, 0), clean_data.len - 1)];
                    var is_number: bool = true;
                    _ = std.fmt.charToDigit(char_around, 10) catch {
                        is_number = false;
                    };
                    const is_non_symbol: bool = char_around == '.' or char_around == 170;
                    const has_symbol_around = !is_number and !is_non_symbol;
                    // std.debug.print("\n{d} [{d: >3} x {d: >3}]  [{d: >2} x {d: >2}] >>> {u} → {any} ", .{
                    //     digit,
                    //     x, y,
                    //     x_o, y_o,
                    //     char_around,
                    //     has_symbol_around,
                    //      });
                    is_part_number = is_part_number or has_symbol_around;
                }
            }
            try numbers.append(digit);
            // std.debug.print("\n{d} {any}\n", .{ digit, numbers.items });
        }
    }

    std.debug.print("\n\nResult: {d}", .{ sum });
}
