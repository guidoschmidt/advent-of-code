const std = @import("std");
const aoc = @import("aoc");

const Allocator = std.mem.Allocator;

fn strToDigit(s: []const u8) u8 {
    const words = [_][]const u8{
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"
    };
    for(words, 1..) |word, i| {
        if (std.mem.eql(u8, word, s)) {
            // std.debug.print("\n>>> {s}", .{ s });
            return @intCast(i);
        }
    }
    return 0;
}

pub fn part1(_: Allocator, input: []const u8) anyerror!void {
    var result: u32 = 0;

    var it = std.mem.tokenize(u8, input, "\n");
    while(it.next()) |v| {
        var number: u32 = 0;
        var first: u8 = 0;
        var last: u8 = 0;

        for(0..v.len) |x| {
            const digit = std.fmt.charToDigit(v[x], 10) catch {
                continue;
            };
            if (first == 0) {
                first = digit;
                break;
            }
        }

        for(0..v.len) |x| {
            const digit = std.fmt.charToDigit(v[v.len - 1 - x], 10) catch 0;
            if (digit != 0) {
                last = digit;
                break;
            }
        }

        number = 10 * first;
        number += last;

        result += number;
    }

    std.debug.print("\nResult: {d}", .{ result });
}

pub fn part2(_: Allocator, input: []const u8) anyerror!void {
    var result: u32 = 0;

    var it = std.mem.tokenize(u8, input, "\n");
    while(it.next()) |v| {
        var number: u32 = 0;
        var first: u8 = 0;
        var last: u8 = 0;

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

        number = 10 * first;
        number += last;

        result += number;
    }

    std.debug.print("\nResult: {d}", .{ result });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try aoc.runPart(allocator, 2023, 1, .PUZZLE, part1);
    try aoc.runPart(allocator, 2023, 1, .PUZZLE, part2);
}
