const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

fn listToNumber(list: std.ArrayList(u8)) u32 {
    var number: u32 = 0;
    for(0..list.items.len) |i| {
        const exp = std.math.pow(u32, 10, @as(u32, @intCast(i)));
        number += list.items[list.items.len - 1 - i] * exp;
    }
    return number;
}

fn expand(allocator: Allocator, data: *[]u8, x: i16, y: i16, x_off: i16, y_off: i16, column_count: i16) !u32 {
    var left_numbers = std.ArrayList(u8).init(allocator);
    var right_numbers = std.ArrayList(u8).init(allocator);
    defer right_numbers.deinit();
    defer left_numbers.deinit();

    for(1..3) |o| {
        const idx_off_l = indexWithOffset(x, y, column_count, x_off - @as(i16, @intCast(o)), y_off, data.len);
        const char = data.*[@intCast(idx_off_l)];
        const found_digit = std.fmt.charToDigit(char, 10) catch {
            break;
        };
        try left_numbers.append(found_digit);
    }
    for(0..3) |o| {
        const idx_off_r = indexWithOffset(x, y, column_count, x_off + @as(i16, @intCast(o)), y_off, data.len);
        const char = data.*[@intCast(idx_off_r)];
        const found_digit = std.fmt.charToDigit(char, 10) catch {
            break;
        };
        try right_numbers.append(found_digit);
    }
    std.mem.reverse(u8, left_numbers.items);
    try left_numbers.appendSlice(right_numbers.items[0..]);
    const number = listToNumber(left_numbers);
    return number;
}

fn indexWithOffset(x: i16, y: i16, col_count: i16, x_o: i16, y_o: i16, data_len: usize) usize {
    const idx = (y + y_o) * col_count + (x + x_o);
    return @min(@max(idx, 0), data_len);
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var clean_input = allocator.alloc(u8, input.len) catch input; 
    _ = std.mem.replace(u8, input, "\n", "", @constCast(clean_input));

    var row_it = std.mem.tokenize(u8, input, "\n");
    const first_row = row_it.next().?;

    const col_count = first_row.len;
    const row_count = row_it.buffer.len / col_count;

    std.debug.print("\nSize: {d} x {d}\n{d}", .{ col_count, row_count, input.len });

    var sum: u32 = 0;

    for(0..col_count) |y| {
        var numbers = std.ArrayList(u8).init(allocator);
        var is_part_number = false;
        std.debug.print("\n", .{});
        for(0..row_count) |x| {
            const idx =  y * col_count + x;
            // std.debug.print("{c}", .{ clean_data[idx] });

            const char = clean_input[idx];

            const digit = std.fmt.charToDigit(char, 10) catch {
                // Not a digit anymore
                if (numbers.items.len == 0) continue;
                    var number: u32 = 0;
                    for(0..numbers.items.len) |i| {
                        const exp = std.math.pow(u32, 10, @as(u32, @intCast(i)));
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
                    const char_around = clean_input[@min(@max(idx_off, 0), clean_input.len - 1)];
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
            numbers.append(digit) catch {
                std.log.err("\nERROR: Could not append {d} to numbers", .{ digit });
            };
            // std.debug.print("\n{d} {any}\n", .{ digit, numbers.items });
        }
    }

    std.debug.print("\n\nResult: {d}", .{ sum });
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var clean_data: []u8 = try allocator.alloc(u8, input.len);
    _ = std.mem.replace(u8, input, "\n", "", clean_data);

    var row_it = std.mem.tokenize(u8, input, "\n");
    const first_row = row_it.next().?;

    const col_count = first_row.len;
    const row_count = row_it.buffer.len / col_count;

    std.debug.print("\nSize: {d} x {d}\n{d}", .{ col_count, row_count, input.len });

    var result: u32 = 0;

    for(0..col_count) |x| {
        for(0..row_count) |y| {
            const idx =  y * col_count + x;
            const char = clean_data[idx];
            if (char != '*') continue;
            std.debug.print("\n{c} [idx {d}] [{d} x {d}]", .{ char, idx, y, x });

            var part_num_count: u8 = 0;
            var gears = std.ArrayList(u32).init(allocator);
            defer gears.deinit();
            for(0..3) |xo| {
                // if (part_num_count == 2) break;
                for(0..3) |yo| {
                    const y_o: i16 = @as(i16, @intCast(yo)) - 1;
                    const x_o: i16 = @as(i16, @intCast(xo)) - 1;
                    if (x_o == 0 and y_o == 0) continue;
                    const idx_off = indexWithOffset(@intCast(x),
                                                    @intCast(y),
                                                    @intCast(col_count),
                                                    x_o,
                                                    y_o,
                                                    clean_data.len);
                    const char_around = clean_data[idx_off];
                    const digit = std.fmt.charToDigit(char_around, 10) catch {
                        continue;
                    };
                    _ = digit;
                    part_num_count += 1;
                    const number = try expand(allocator,
                                              &clean_data,
                                              @as(i16, @intCast(x)),
                                              @as(i16, @intCast(y)),
                                              x_o,
                                              y_o,
                                              @intCast(col_count));
                    var already_in = false;
                    for(gears.items) |item| {
                        if (item == number) already_in = true;
                    }
                    if (already_in) continue;
                    try gears.append(number);
                }
            }

            std.debug.print("\n  → {d} Gears: {any}", .{
                part_num_count, gears.items
            });
            if (gears.items.len >= 2) {
                result += gears.items[0] * gears.items[1];
            }
        }
    }

    std.debug.print("\n\nResult: {d}", .{ result });
    
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try common.runDay(allocator, 3, .PUZZLE, part1, part2);
}
