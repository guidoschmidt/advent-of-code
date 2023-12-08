const std = @import("std");

// one
// two
// three
// four
// five
// six
// seven
// eight
// nine

fn strToDigit(s: []const u8) u8 {
    const words = [_][]const u8{
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"
    };
    for(words, 1..) |word, i| {
        if (std.mem.eql(u8, word, s)) {
            std.debug.print("\n>>> {s}", .{ s });
            return @intCast(i);
        }
    }
    return 0;
}

pub fn main() !void {
    const data = @embedFile("./data/day1.txt");
    var result: u32 = 0;

    var it = std.mem.tokenize(u8, data, "\n");
    while(it.next()) |v| {
        // std.debug.print("\n{s}", .{ v });
        var number: u32 = 0;
        var first: u8 = 0;
        var last: u8 = 0;

        std.debug.print("\n\n{s}", .{ v });
        for(0..v.len) |x| {
            if (v.len >= 3 and x < v.len - 3) {
                const word = v[x..x + 3];
                const digit = strToDigit(word);
                if (digit != 0 and first == 0) {
                    first = digit;
                    break;
                }
            }
            if (v.len >= 4 and x < v.len - 4) {
                const word = v[x..x + 4];
                const digit = strToDigit(word);
                if (digit != 0 and first == 0) {
                    first = digit;
                    break;
                }
            }
            if (v.len >= 5 and x < v.len - 5) {
                const word = v[x..x + 5];
                const digit = strToDigit(word);
                if (digit != 0 and first == 0) {
                    first = digit;
                    break;
                }
            }
            const digit = std.fmt.charToDigit(v[x], 10) catch {
                continue;
            };
            if (first == 0) {
                first = digit;
                break;
            }
        }
        std.debug.print("\n[FIRST]: {d}", .{ first });

        for(0..v.len) |x| {
            var digit = std.fmt.charToDigit(v[v.len - 1 - x], 10) catch 0;
            if (digit != 0) {
                last = digit;
                break;
            }

            const end = v.len - x;
            if (v.len >= 3 and x < v.len - 3) {
                const start = end - 3;
                const word = v[start..end];
                std.debug.print("\n...{s}", .{ word });
                digit = strToDigit(word);
                if (digit != 0) {
                    last = digit;
                    break;
                }
            }
            if (v.len >= 4 and x < v.len - 4) {
                const start = end - 4;
                const word = v[start..end];
                digit = strToDigit(word);
                if (digit != 0) {
                    last = digit;
                    break;
                }
            }
            if (v.len >= 5 and x < v.len - 5) {
                const start = end - 5;
                const word = v[start..end];
                digit = strToDigit(word);
                if (digit != 0) {
                    last = digit;
                    break;
                }
            }
        }
        std.debug.print("\n[LAST]: {d}", .{ last });

        // std.debug.print("\n{s} ", .{ v });
        // std.debug.print(" → [first, last] [{d}, {d}], ", .{ first, last });

        number = 10 * first;
        number += last;
        // std.debug.print(" → [{d}]", .{ number });

        result += number;
    }

    std.debug.print("\nResult: {d}", .{ result });
}
