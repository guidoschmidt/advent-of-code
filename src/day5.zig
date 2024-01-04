const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const SeedRange = struct {
    start: u64,
    range: u64,
};

const Map = struct {
    src: u64,
    dst: u64,
    range: u64,
};

fn mapper(map: *std.ArrayList(Map), src: u64) u64 {
    for(map.items) |s| {
        if (src >= s.src and src < s.src + s.range) {
            return s.dst + (src - s.src);
        } 
    }
    return src;
}

fn inv_mapper(map: *std.ArrayList(Map), dst: u64) u64 {
    for(map.items) |s| {
        if (dst >= s.dst and dst < s.dst + s.range) {
            return s.src + (dst - s.dst);
        }
    }
    return dst;
}

fn parseAndFillMap(row_it: *std.mem.TokenIterator(u8, .any), list: *std.ArrayList(Map)) !void {
    const dst = try std.fmt.parseInt(u64, row_it.next().?, 10);
    const src = try std.fmt.parseInt(u64, row_it.next().?, 10);
    const range = try std.fmt.parseInt(u64, row_it.next().?, 10);
    try list.append(Map{
        .src = src,
        .dst = dst,
        .range = range
    });
}

fn part1() !void {
    var seeds = std.ArrayList(u64).init(allocator);
    var soil = std.ArrayList(Map).init(allocator);
    var fert = std.ArrayList(Map).init(allocator);
    var water = std.ArrayList(Map).init(allocator);
    var light = std.ArrayList(Map).init(allocator);
    var temp = std.ArrayList(Map).init(allocator);
    var hum = std.ArrayList(Map).init(allocator);
    var loc = std.ArrayList(Map).init(allocator);

    defer seeds.deinit();
    defer soil.deinit();
    defer fert.deinit();
    defer water.deinit();
    defer light.deinit();
    defer temp.deinit();
    defer hum.deinit();
    defer loc.deinit();

    const data = @embedFile("data/day5-test.txt");
    var parts_it = std.mem.tokenize(u8, data, "\n");
    var current_map: []const u8 = "";

    while (parts_it.next()) |part| {
        if (std.mem.containsAtLeast(u8, part, 1, ":")) {
            current_map = part;
            continue;
        }
        var row_it = std.mem.tokenize(u8, part, " ");
        if (std.mem.eql(u8, current_map, "seeds:")) {
            while (row_it.next()) |v| {
                const seed = std.fmt.parseInt(u64, v, 10) catch continue;
                try seeds.append(seed);
            }
        }
        if (std.mem.eql(u8, current_map, "seed-to-soil map:")) {
            try parseAndFillMap(&row_it, &soil);
        }
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            try parseAndFillMap(&row_it, &fert);
        }
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            try parseAndFillMap(&row_it, &water);
        }
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            try parseAndFillMap(&row_it, &light);
        }
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            try parseAndFillMap(&row_it, &temp);
        }
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            try parseAndFillMap(&row_it, &hum);
        }
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            try parseAndFillMap(&row_it, &loc);
        }
    }

    var lowest: u64 = std.math.maxInt(u64) - 1;
    for(seeds.items) |s| {
        const r_soil = mapper(&soil, s);
        const r_fert = mapper(&fert, r_soil);
        const r_water = mapper(&water, r_fert);
        const r_light = mapper(&light, r_water);
        const r_temp = mapper(&temp, r_light);
        const r_hum = mapper(&hum, r_temp);
        const r_loc = mapper(&loc, r_hum);
        if (lowest > r_loc)
            lowest = r_loc;
    }
    std.debug.print("\n\n############ PART 1 ###############\n", .{});
    std.debug.print("\n\n{d}\n", .{lowest});
}

fn part2() !void {
    var seeds = std.ArrayList(SeedRange).init(allocator);
    var soil = std.ArrayList(Map).init(allocator);
    var fert = std.ArrayList(Map).init(allocator);
    var water = std.ArrayList(Map).init(allocator);
    var light = std.ArrayList(Map).init(allocator);
    var temp = std.ArrayList(Map).init(allocator);
    var hum = std.ArrayList(Map).init(allocator);
    var loc = std.ArrayList(Map).init(allocator);

    defer seeds.deinit();
    defer soil.deinit();
    defer fert.deinit();
    defer water.deinit();
    defer light.deinit();
    defer temp.deinit();
    defer hum.deinit();
    defer loc.deinit();

    const data = @embedFile("data/day5-test.txt");
    var parts_it = std.mem.tokenize(u8, data, "\n");
    var current_map: []const u8 = "";

    while (parts_it.next()) |part| {
        if (std.mem.containsAtLeast(u8, part, 1, ":")) {
            current_map = part;
            continue;
        }
        var row_it = std.mem.tokenize(u8, part, " ");
        if (std.mem.eql(u8, current_map, "seeds:")) {
            while (row_it.next()) |v| {
                const seed_start = std.fmt.parseInt(u64, v, 10) catch continue;
                const seed_range = std.fmt.parseInt(u64, row_it.next().?, 10) catch continue;
                try seeds.append(SeedRange{
                    .start = seed_start,
                    .range = seed_range
                });
            }
        }
        if (std.mem.eql(u8, current_map, "seed-to-soil map:")) {
            try parseAndFillMap(&row_it, &soil);
        }
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            try parseAndFillMap(&row_it, &fert);
        }
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            try parseAndFillMap(&row_it, &water);
        }
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            try parseAndFillMap(&row_it, &light);
        }
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            try parseAndFillMap(&row_it, &temp);
        }
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            try parseAndFillMap(&row_it, &hum);
        }
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            try parseAndFillMap(&row_it, &loc);
        }
    }

    var lowest: u64 = std.math.maxInt(u64) - 1;
    for(seeds.items) |s| {
        const r_soil = mapper(&soil, s.start);
        const r_fert = mapper(&fert, r_soil);
        const r_water = mapper(&water, r_fert);
        const r_light = mapper(&light, r_water);
        const r_temp = mapper(&temp, r_light);
        const r_hum = mapper(&hum, r_temp);
        const r_loc = mapper(&loc, r_hum);
        if (lowest > r_loc)
            lowest = r_loc;
    }

    for(0..lowest) |l| {
        const r_hum = inv_mapper(&loc, l);
        const r_temp = inv_mapper(&hum,r_hum);
        const r_light = inv_mapper(&temp,r_temp);
        const r_water = inv_mapper(&light, r_light);
        const r_fert = inv_mapper(&water, r_water);
        const r_soil = inv_mapper(&fert, r_fert);
        const r_seed = inv_mapper(&soil, r_soil);
        std.debug.print("\n{d} -> {d} -> {d} -> {d} -> {d} -> {d} -> {d}",
                        .{ r_seed, r_soil, r_fert, r_water, r_light, r_temp, r_hum });
        for(seeds.items) |seed_range| {
            if (r_seed >= seed_range.start and r_seed < seed_range.start + seed_range.range and l < lowest) {
                lowest = l;
            }
        }
    }

    std.debug.print("\n\n############ PART 2 ###############\n", .{});
    std.debug.print("\n\n{d}\n", .{ lowest });
   
}

pub fn main() !void {
    try part1();
    try part2();
}
