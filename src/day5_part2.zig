const std = @import("std");
const sw = @import("stopwatch.zig");

const Range = struct { start: u64, end: u64, length: u64 };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var seeds_list = std.ArrayList(u64).init(allocator);
var seed_range_list = std.ArrayList(Range).init(allocator);
var seed_to_soil_map = std.AutoHashMap(Range, Range).init(allocator);
var soil_to_fertilizer_map = std.AutoHashMap(Range, Range).init(allocator);
var fertilizer_to_water_map = std.AutoHashMap(Range, Range).init(allocator);
var water_to_light_map = std.AutoHashMap(Range, Range).init(allocator);
var light_to_temperature_map = std.AutoHashMap(Range, Range).init(allocator);
var temperature_to_humidity_map = std.AutoHashMap(Range, Range).init(allocator);
var humidity_to_location_map = std.AutoHashMap(Range, Range).init(allocator);

fn resolveLocationFromSeed(seed: u64, locations: *std.ArrayList(u64)) !void {
    const soil: u64 = resolveDestination(seed_to_soil_map, seed);
    const fertilizer: u64 = resolveDestination(soil_to_fertilizer_map, soil);
    const water: u64 = resolveDestination(fertilizer_to_water_map, fertilizer);
    const light: u64 = resolveDestination(water_to_light_map, water);
    const temperature: u64 = resolveDestination(light_to_temperature_map, light);
    const humidity: u64 = resolveDestination(temperature_to_humidity_map, temperature);
    const location: u64 = resolveDestination(humidity_to_location_map, humidity);
    std.debug.print("\n>> Seed {d} → Soil {d} → Fert {d} → Water {d} → Light {d} → Temp {d} → Humid {d} → Location {d}", .{ seed, soil, fertilizer, water, light, temperature, humidity, location });
    try locations.append(location);
}

fn resolveLocationFromSeedRange(seed_range: Range, locations: *std.ArrayList(u64)) !void {
    for (seed_range.start..seed_range.end) |seed| {
        try resolveLocationFromSeed(seed, locations);
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

pub fn main() !void {
    sw.start();

    const data = @embedFile("data/day5.txt");
    var parts_it = std.mem.tokenize(u8, data, "\n");
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
            try parseAndFillMap(&row_it, &seed_to_soil_map);
        }
        // Soil → Fertilizer
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            try parseAndFillMap(&row_it, &soil_to_fertilizer_map);
        }
        // Fertilizer → Water
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            try parseAndFillMap(&row_it, &fertilizer_to_water_map);
        }
        // Water → Light
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            try parseAndFillMap(&row_it, &water_to_light_map);
        }
        // Light → Temperature
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            try parseAndFillMap(&row_it, &light_to_temperature_map);
        }
        // Temperature → Humidity
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            try parseAndFillMap(&row_it, &temperature_to_humidity_map);
        }
        // Humidity → Location
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            try parseAndFillMap(&row_it, &humidity_to_location_map);
        }
    }

    // Part 1
    // std.debug.print("\n\n############ PART 1 ###############\n", .{});
    // var results = std.ArrayList(u64).init(allocator);
    // for (seeds_list.items) |seed| {
    //     const t = try std.Thread.spawn(.{}, resolveLocationFromSeed, .{ seed, &results });
    //     t.join();
    // }
    // var lowest: u64 = std.math.maxInt(u64) - 1;
    // for (0..results.items.len) |i| {
    //     if (results.items[i] < lowest) {
    //         lowest = results.items[i];
    //     }
    // }
    // const time = sw.stop();
    // std.debug.print("\n\nResult:\n{d}\n{d:3} ms\n", .{ lowest, time });

    // Part 2
    std.debug.print("\n\n############ PART 2 ###############\n", .{});
    var results_part2 = std.ArrayList(u64).init(allocator);
    for(seed_range_list.items) |seed_range| {
        const t = try std.Thread.spawn(.{}, resolveLocationFromSeedRange, .{ seed_range, &results_part2 });
        t.join();
    }
    var lowest_part2: u64 = std.math.maxInt(u64) - 1;
    for (0..results_part2.items.len) |i| {
        if (results_part2.items[i] < lowest_part2) {
            lowest_part2 = results_part2.items[i];
        }
    }

    const time_part2 = sw.stop();
    std.debug.print("\n\nResult:\n{d}\n{d:3} ms\n", .{ lowest_part2, time_part2 });
}
