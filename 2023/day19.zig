const std = @import("std");
const aoc = @import("aoc");

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

    pub fn format(self: PartRating,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("[x: {d}, m: {d}, a: {d}, s: {d}]", .{ self.x, self.m, self.x, self.s });
    }

    pub fn sum(self: *PartRating) u32 {
        return self.x + self.m + self.a + self.s;
    }
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

    pub fn process(self: *Workflow, part_rating: PartRating) []const u8 {
        for(self.rules) |*rule| {
            if (rule.applies(part_rating)) {
                const next_workflow = rule.next;
                return next_workflow;
            }
        }
        return "";
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

    pub fn applies(self: *Rule, part_rating: PartRating) bool {
        // std.debug.print("\n\n{any} <--> {any}", .{ self, part_rating });
        if (self.category == null) return true;
        std.debug.print("\n    ({any} {c} {any})", .{ self.category.?, self.comparator.?, self.threshold.? });
        switch(self.category.?) {
            Category.x => {
                return switch(self.comparator.?) {
                    '<' => part_rating.x < self.threshold.?,
                    '>' => part_rating.x > self.threshold.?,
                    else => false,
                };
            },
            Category.m => {
                return switch(self.comparator.?) {
                    '<' => part_rating.m < self.threshold.?,
                    '>' => part_rating.m > self.threshold.?,
                    else => false,
                };
            },
            Category.a => {
                return switch(self.comparator.?) {
                    '<' => part_rating.a < self.threshold.?,
                    '>' => part_rating.a > self.threshold.?,
                    else => false,
                };
            },
            Category.s => {
                return switch(self.comparator.?) {
                    '<' => part_rating.s < self.threshold.?,
                    '>' => part_rating.s > self.threshold.?,
                    else => false,
                };
            },
        }
    }
};

const WorkItem = struct {
    part_rating: PartRating,
    workflow: Workflow,
};

fn part1(gpa: Allocator, input: []const u8) anyerror!void {
    var row_it = std.mem.tokenize(u8, input, "\n");

    var part_ratings = std.ArrayList(PartRating).init(gpa);
    var workflows = std.StringHashMap(Workflow).init(gpa);

    while (row_it.next()) |row| {
        // Workflows
        if (row[0] != '{') {
            var name_it = std.mem.split(u8, row, "{");
            const name = name_it.next().?;
            const workflow_str = name_it.next().?;
            var rules_it = std.mem.tokenize(u8, workflow_str[0..workflow_str.len - 1], ",");
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
                        .comparator = '>',
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
            // try workflows.append(workflow);
            try workflows.put(workflow.name, workflow);
        }

        // Part ratings
        if (row[0] == '{') {
            var ratings_it = std.mem.tokenize(u8, row[1..row.len-1], ",");
            var part_rating = PartRating{};
            while (ratings_it.next()) |rating_str| {
                var rating_it = std.mem.split(u8, rating_str, "=");
                const cat =  rating_it.next().?[0];
                const num_str =  rating_it.next().?;
                const num = try std.fmt.parseInt(u16, num_str, 10);
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
    }

    // std.debug.print("\nWorkflows: ", .{});
    // var workflow_it = workflows.iterator();
    // while (workflow_it.next()) |wf| {
    //     std.debug.print("\nWorkflow: {any}", .{ wf });
    // }

    var accepted = std.ArrayList(PartRating).init(gpa);
    const start_workflow_name = "in";
    const start_workflow = workflows.get(start_workflow_name).?;
    // std.debug.print("\nStart: {any}", .{ start_workflow });

    var work_queue = std.ArrayList(WorkItem).init(gpa);
    for (0..part_ratings.items.len) |idx| {
        try work_queue.append(WorkItem{
            .part_rating = part_ratings.items[idx],
            .workflow = start_workflow,
        });
    }
    while(work_queue.items.len > 0) {
        const curr_item = work_queue.pop();
        var curr_workflow = curr_item.workflow;
        const curr_part_rating = curr_item.part_rating;
        const next_workflow_name = curr_workflow.process(curr_part_rating);
        if (std.mem.eql(u8, next_workflow_name, "A")) {
            try accepted.append(curr_part_rating);
            continue;
        }
        if (workflows.contains(next_workflow_name)) {
            try work_queue.append(WorkItem {
                .workflow = workflows.get(next_workflow_name).?,
                .part_rating = curr_part_rating,
            });
        }
    }

    var result: u32 = 0;
    for (accepted.items) |*a| {
        result += a.sum();
    }
    std.debug.print("\n\nResult: {d}", .{ result });
}

fn part2(gpa: Allocator, input: []const u8) anyerror!void {
    _ = input;
    _ = gpa;
}

pub fn main() !void {
    var gpa_generator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_generator.allocator();

    try aoc.runPart(gpa, 2023, 19, .PUZZLE, part1);
    try aoc.runPart(gpa, 2023, 19, .PUZZLE, part2);
}
