const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Category = enum(u4) {
    x,
    m,
    a,
    s,

    pub fn format(self: Category,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s}", .{ @tagName(self) });
    }
};


const PartRating = struct {
    x: u16 = undefined,
    m: u16 = undefined,
    a: u16 = undefined,
    s: u16 = undefined,
};

const Workflow = struct {
    name: []const u8 = undefined,
    rules: []Rule = undefined,

    pub fn format(self: Workflow,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("[{s}]\nRules:", .{ self.name });
        for (self.rules) |rule| {
            try writer.print("\n{any}", .{ rule });
        }
    }
};

const Rule = struct {
    category: ?Category = null,
    comparator: ?u8 = null,
    threshold: ?u16 = null,
    next: []const u8,

   pub fn format(self: Rule,
                 comptime fmt: []const u8,
                 options: std.fmt.FormatOptions,
                 writer: anytype) !void {
       _ = fmt;
       _ = options;
       if (self.category == null or self.comparator == null or self.threshold == null) {
           try writer.print("→ {s}", .{ self.next });
           return;
       }
       try writer.print("{any} {c} {d} → {s}", .{ self.category.?, self.comparator.?, self.threshold.?, self.next });
    }
};

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var part_ratings = std.ArrayList(PartRating).init(gpa);
    var workflows = std.ArrayList(Workflow).init(gpa);

    while (row_it.next()) |row| {
        // Workflows
        if (row[0] != '{') {
            var name_it = std.mem.split(u8, row, "{");
            const name = name_it.next().?;
            const workflow_str = name_it.next().?;
            var rules_it = std.mem.tokenize(u8, workflow_str[0..workflow_str.len - 1], ",");
            std.debug.print("\n[{s}] ... Rules:", .{ name });
            var rule_list = std.ArrayList(Rule).init(gpa);
            while(rules_it.next()) |rule_str| {
                if (std.mem.containsAtLeast(u8, rule_str, 1, "<")) {
                    const idx_comp = std.mem.indexOf(u8, rule_str, "<").?;
                    const idx_next = std.mem.indexOf(u8, rule_str, ":").?;
                    const rule = Rule {
                        .category = switch (rule_str[0]) {
                            'x' => Category.x,
                            'm' => Category.m,
                            'a' => Category.a,
                            's' => Category.s,
                            else => unreachable,
                        },
                        .threshold = try std.fmt.parseInt(u16, rule_str[idx_comp + 1..idx_next], 10),
                        .comparator = '<',
                        .next = rule_str[idx_next + 1..],
                    };
                    try rule_list.append(rule);
                }
                else if (std.mem.containsAtLeast(u8, rule_str, 1, ">")) {
                    const idx_comp = std.mem.indexOf(u8, rule_str, ">").?;
                    const idx_next = std.mem.indexOf(u8, rule_str, ":").?;
                    const rule = Rule {
                        .category = switch (rule_str[0]) {
                            'x' => Category.x,
                            'm' => Category.m,
                            'a' => Category.a,
                            's' => Category.s,
                            else => unreachable,
                        },
                        .threshold = try std.fmt.parseInt(u16, rule_str[idx_comp + 1..idx_next], 10),
                        .comparator = '<',
                        .next = rule_str[idx_next + 1..],
                    };
                    try rule_list.append(rule);
                }
                else {
                    const rule = Rule {
                        .next = rule_str
                    };
                    try rule_list.append(rule);
                }
            }
            const workflow = Workflow {
                .name = name,
                .rules = rule_list.items,
            };
            try workflows.append(workflow);
        }

        // Part ratings
        if (row[0] == '{') {
            var ratings_it = std.mem.tokenize(u8, row[1..row.len-1], ",");
            var part_rating = PartRating{};
            while (ratings_it.next()) |rating_str| {
                var rating_it = std.mem.split(u8, rating_str, "=");
                var cat =  rating_it.next().?[0];
                var num_str =  rating_it.next().?;
                var num = try std.fmt.parseInt(u16, num_str, 10);
                switch (cat) {
                    'x' => part_rating.x = num,
                    'm' => part_rating.m = num,
                    'a' => part_rating.a = num,
                    's' => part_rating.s = num,
                    else => unreachable,
                }
            }
            try part_ratings.append(part_rating);
        }

        for(part_ratings.items) |pr| {
            std.debug.print("\n{any}", .{ pr });
        }

        for (workflows.items) |wf| {
            std.debug.print("\n{any}", .{ wf });
        }
    }
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = input;
    _ = gpa;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try common.runPart(gpa, 19, .EXAMPLE, part1);
    // try common.runPart(gpa, 19, .PUZZLE, part2);
}
