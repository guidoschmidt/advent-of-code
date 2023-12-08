const std = @import("std");

const data = @embedFile("./data/day3-test.txt");

fn checkLeft() void {

}

fn checkRight() void {

}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const clean_data = try allocator.alloc(u8, data.len);
    _ = std.mem.replace(u8, data, "\n", "", clean_data);

    var row_it = std.mem.tokenize(u8, data, "\n");
    const first_row = row_it.next().?;

    const col_count = first_row.len;
    const row_count = row_it.buffer.len / col_count;

    std.debug.print("\nSize: {d} x {d}\n{d}", .{ col_count, row_count, data.len });

    for(0..col_count) |y| {
        for(0..row_count) |x| {
            const idx =  y * col_count + x;
            const char = clean_data[idx];
            if (char != '*') continue;
            std.debug.print("\n{c}", .{ char });

            for(0..3) |xo| {
                for(0..3) |yo| {
                    const y_o: i16 = @as(i16, @intCast(yo)) - 1;
                    const x_o: i16 = @as(i16, @intCast(xo)) - 1;
                    if (x_o == 0 and y_o == 0) continue;
                    const idx_off: i16 = (@as(i16, @intCast(y)) + x_o) *
                        @as(i16, @intCast(col_count)) +
                        (@as(i16, @intCast(x)) + y_o);
                    const char_around = clean_data[@min(@max(idx_off, 0), clean_data.len - 1)];
                    const digit = std.fmt.charToDigit(char_around, 10) catch {
                        continue;
                    };
                    std.debug.print("\n>>> Found digit {d} [{d} x {d}]", .{ digit, x_o, y_o });
                }
            }
        }
    }
}
