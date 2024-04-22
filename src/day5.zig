const std = @import("std");
const common = @import("common.zig");

const Allocator = std.mem.Allocator;

const Range = struct { start: u64, end: u64, length: ?u64 = 0 };

const MapRange = struct { dest_range_start: u64, range_length: u64 };

const Maps = struct {
    seed_to_soil: std.AutoHashMap(Range, MapRange),
    soil_to_fertilizer: std.AutoHashMap(Range, MapRange),
    fertilizer_to_water: std.AutoHashMap(Range, MapRange),
    water_to_light: std.AutoHashMap(Range, MapRange),
    light_to_temperature: std.AutoHashMap(Range, MapRange),
    temperature_to_humidity: std.AutoHashMap(Range, MapRange),
    humidity_to_location: std.AutoHashMap(Range, MapRange),
};

fn resolveChain(seed: u64, locations: *std.ArrayList(u64), maps: *Maps) !void {
    const soil: u64 = resolve(&maps.seed_to_soil, seed);
    const fertilizer: u64 = resolve(&maps.soil_to_fertilizer, soil);
    const water: u64 = resolve(&maps.fertilizer_to_water, fertilizer);
    const light: u64 = resolve(&maps.water_to_light, water);
    const temperature: u64 = resolve(&maps.light_to_temperature, light);
    const humidity: u64 = resolve(&maps.temperature_to_humidity, temperature);
    const location: u64 = resolve(&maps.humidity_to_location, humidity);
    std.debug.print("\n>> Seed {d} → Soil {d} → Fert {d} → Water {d} → Light {d} → Temp {d} → Humid {d} → Location {d}",
                    .{ seed, soil, fertilizer, water, light, temperature, humidity, location });
    try locations.append(location);
}

fn resolve(map: *std.AutoHashMap(Range, MapRange), start_value: u64) u64 {
    var it = map.keyIterator();
    var result: u64 = start_value;
    while (it.next()) |range| {
        if (result >= range.start and result <= range.end) {
            result = map.get(range.*).?.dest_range_start + start_value - range.start;
            break;
        }
    }
    return result;
}

fn part1(allocator: Allocator, input: []const u8) anyerror!void {
    var seeds_list = std.ArrayList(u64).init(allocator);

    var maps = Maps{
        .seed_to_soil = std.AutoHashMap(Range, MapRange).init(allocator),
        .soil_to_fertilizer = std.AutoHashMap(Range, MapRange).init(allocator),
        .fertilizer_to_water = std.AutoHashMap(Range, MapRange).init(allocator),
        .water_to_light = std.AutoHashMap(Range, MapRange).init(allocator),
        .light_to_temperature = std.AutoHashMap(Range, MapRange).init(allocator),
        .temperature_to_humidity = std.AutoHashMap(Range, MapRange).init(allocator),
        .humidity_to_location = std.AutoHashMap(Range, MapRange).init(allocator),
    };

    var parts_it = std.mem.tokenize(u8, input, "\n");
    var current_map: []const u8 = "";
    while (parts_it.next()) |part| {
        // std.debug.print("\n{s}", .{ part });
        if (std.mem.containsAtLeast(u8, part, 1, ":")) {
            current_map = part;
            // std.debug.print("\n----→ {s}", .{ current_map });
            continue;
        }

        var row_it = std.mem.tokenize(u8, part, " ");

        // Seeds
        if (std.mem.eql(u8, current_map, "seeds:")) {
            while (row_it.next()) |v| {
                const number = std.fmt.parseInt(u64, v, 10) catch {
                    continue;
                };
                std.debug.print("\n{d}", .{ number });
                try seeds_list.append(number);
            }
        }

        // Seed → Soil
        if (std.mem.eql(u8, current_map, "seed-to-soil map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            // std.debug.print("\n{d} -> [{d} - {d}]", .{ src_range, dst_range, dst_range + range_len });
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.seed_to_soil.put(range, mappedRange);
        }

        // Soil → Fertilizer
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.soil_to_fertilizer.put(range, mappedRange);
        }

        // Fertilizer → Water
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.fertilizer_to_water.put(range, mappedRange);
        }

        // Water → Light
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.water_to_light.put(range, mappedRange);
        }

        // Light → Temperature
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.light_to_temperature.put(range, mappedRange);
        }

        // Temperature → Humidity
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.temperature_to_humidity.put(range, mappedRange);
        }

        // Humidity → Location
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try maps.humidity_to_location.put(range, mappedRange);
        }
    }

    var locations = std.ArrayList(u64).init(allocator);
    for (seeds_list.items) |seed| {
        const t = try std.Thread.spawn(.{}, resolveChain, .{ seed, &locations, &maps });
        t.join();
    }

    var lowest: u64 = locations.items[0];
    for (1..locations.items.len) |i| {
        if (locations.items[i] < lowest) {
            lowest = locations.items[i];
        }
    }
    std.debug.print("\n\nResult:\n{d}", .{ lowest });
}


const MapsPart2 = struct {
    seed_to_soil: std.AutoHashMap(Range, Range),
    soil_to_fertilizer: std.AutoHashMap(Range, Range),
    fertilizer_to_water: std.AutoHashMap(Range, Range),
    water_to_light: std.AutoHashMap(Range, Range),
    light_to_temperature: std.AutoHashMap(Range, Range),
    temperature_to_humidity: std.AutoHashMap(Range, Range),
    humidity_to_location: std.AutoHashMap(Range, Range),
};

fn resolveLocationFromSeed(seed: u64, locations: *std.ArrayList(u64), maps: *MapsPart2) !void {
    const soil: u64 = resolveDestination(maps.seed_to_soil, seed);
    const fertilizer: u64 = resolveDestination(maps.soil_to_fertilizer, soil);
    const water: u64 = resolveDestination(maps.fertilizer_to_water, fertilizer);
    const light: u64 = resolveDestination(maps.water_to_light, water);
    const temperature: u64 = resolveDestination(maps.light_to_temperature, light);
    const humidity: u64 = resolveDestination(maps.temperature_to_humidity, temperature);
    const location: u64 = resolveDestination(maps.humidity_to_location, humidity);
    std.debug.print("\n>> Seed {d} → Soil {d} → Fert {d} → Water {d} → Light {d} → Temp {d} → Humid {d} → Location {d}", .{ seed, soil, fertilizer, water, light, temperature, humidity, location });
    try locations.append(location);
}

fn resolveLocationFromSeedRange(seed_range: Range, locations: *std.ArrayList(u64), maps: *MapsPart2) !void {
    for (seed_range.start..seed_range.end) |seed| {
        try resolveLocationFromSeed(seed, locations, maps);
    }
}

fn resolveDestination(map: std.AutoHashMap(Range, Range), start_value: u64) u64 {
    var it = map.keyIterator();
    var result: u64 = start_value;
    while (it.next()) |range| {
        if (result >= range.start and result <= range.end) {
            result = map.get(range.*).?.start + start_value - range.start;
            break;
        }
    }
    return result;
}

fn parseAndFillMap(row_it: *std.mem.TokenIterator(u8, .any), map: *std.AutoHashMap(Range, Range)) !void {
    const dst_start = try std.fmt.parseInt(u64, row_it.next().?, 10);
    const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
    const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
    const range = Range{ .start = src_range, .end = src_range + range_len, .length = range_len };
    const mappedRange = Range{ .start = dst_start, .end = dst_start + range_len, .length = range_len };
    try map.put(range, mappedRange);
}

fn part2(allocator: Allocator, input: []const u8) anyerror!void {
    var seeds_list = std.ArrayList(u64).init(allocator);
    var seed_range_list = std.ArrayList(Range).init(allocator);

    var maps = MapsPart2 {
        .seed_to_soil = std.AutoHashMap(Range, Range).init(allocator),
        .soil_to_fertilizer = std.AutoHashMap(Range, Range).init(allocator),
        .fertilizer_to_water = std.AutoHashMap(Range, Range).init(allocator),
        .water_to_light = std.AutoHashMap(Range, Range).init(allocator),
        .light_to_temperature = std.AutoHashMap(Range, Range).init(allocator),
        .temperature_to_humidity = std.AutoHashMap(Range, Range).init(allocator),
        .humidity_to_location = std.AutoHashMap(Range, Range).init(allocator),
    };

    var parts_it = std.mem.tokenize(u8, input, "\n");
    var current_map: []const u8 = "";
    while (parts_it.next()) |part| {
        if (std.mem.containsAtLeast(u8, part, 1, ":")) {
            current_map = part;
            // std.debug.print("\n----→ {s}", .{ current_map });
            continue;
        }

        var row_it = std.mem.tokenize(u8, part, " ");

        // Seeds
        if (std.mem.eql(u8, current_map, "seeds:")) {
            while (row_it.next()) |v| {
                const start = std.fmt.parseInt(u64, v, 10) catch {
                    continue;
                };
                try seeds_list.append(start);
            }
            row_it.reset();
            while(row_it.next()) |v| {
                const start = std.fmt.parseInt(u64, v, 10) catch {
                    continue;
                };
                const length = std.fmt.parseInt(u64, row_it.next().?, 10) catch {
                    continue;
                };
                try seed_range_list.append(Range{ .start = start, .end = start + length, .length = length });
            }
        }

        // Seed → Soil
        if (std.mem.eql(u8, current_map, "seed-to-soil map:")) {
            try parseAndFillMap(&row_it, &maps.seed_to_soil);
        }
        // Soil → Fertilizer
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            try parseAndFillMap(&row_it, &maps.soil_to_fertilizer);
        }
        // Fertilizer → Water
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            try parseAndFillMap(&row_it, &maps.fertilizer_to_water);
        }
        // Water → Light
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            try parseAndFillMap(&row_it, &maps.water_to_light);
        }
        // Light → Temperature
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            try parseAndFillMap(&row_it, &maps.light_to_temperature);
        }
        // Temperature → Humidity
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            try parseAndFillMap(&row_it, &maps.temperature_to_humidity);
        }
        // Humidity → Location
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            try parseAndFillMap(&row_it, &maps.humidity_to_location);
        }
    }

    // Part 2
    std.debug.print("\n\n############ PART 2 ###############\n", .{});
    var results_part2 = std.ArrayList(u64).init(allocator);
    for(seed_range_list.items) |seed_range| {
        const t = try std.Thread.spawn(.{}, resolveLocationFromSeedRange, .{ seed_range, &results_part2, &maps });
        t.join();
    }
    var lowest_part2: u64 = std.math.maxInt(u64) - 1;
    for (0..results_part2.items.len) |i| {
        if (results_part2.items[i] < lowest_part2) {
            lowest_part2 = results_part2.items[i];
        }
    }

    std.debug.print("\n\nResult:\n{d}", .{ lowest_part2 });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try common.runDay(allocator, 5, .PUZZLE, part1, part2);
}
