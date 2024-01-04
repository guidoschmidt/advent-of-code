const std = @import("std");
const sw = @import("stopwatch.zig");

const Range = struct { start: u64, end: u64 };

const MapRange = struct { dest_range_start: u64, range_length: u64 };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var seeds_list = std.ArrayList(u64).init(allocator);
var seed_to_soil_map = std.AutoHashMap(Range, MapRange).init(allocator);
var soil_to_fertilizer_map = std.AutoHashMap(Range, MapRange).init(allocator);
var fertilizer_to_water_map = std.AutoHashMap(Range, MapRange).init(allocator);
var water_to_light_map = std.AutoHashMap(Range, MapRange).init(allocator);
var light_to_temperature_map = std.AutoHashMap(Range, MapRange).init(allocator);
var temperature_to_humidity_map = std.AutoHashMap(Range, MapRange).init(allocator);
var humidity_to_location_map = std.AutoHashMap(Range, MapRange).init(allocator);

fn resolveChain(seed: u64, locations: *std.ArrayList(u64)) !void {
    const soil: u64 = resolve(seed_to_soil_map, seed);
    const fertilizer: u64 = resolve(soil_to_fertilizer_map, soil);
    const water: u64 = resolve(fertilizer_to_water_map, fertilizer);
    const light: u64 = resolve(water_to_light_map, water);
    const temperature: u64 = resolve(light_to_temperature_map, light);
    const humidity: u64 = resolve(temperature_to_humidity_map, temperature);
    const location: u64 = resolve(humidity_to_location_map, humidity);
    std.debug.print("\n>> Seed {d} → Soil {d} → Fert {d} → Water {d} → Light {d} → Temp {d} → Humid {d} → Location {d}",
                    .{ seed, soil, fertilizer, water, light, temperature, humidity, location });
    try locations.append(location);
}

fn resolve(map: std.AutoHashMap(Range, MapRange), start_value: u64) u64 {
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

pub fn main() !void {
    sw.start();

    const data = @embedFile("data/day5-test.txt");
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
                const number = std.fmt.parseInt(u64, v, 10) catch {
                    continue;
                };
                // std.debug.print("\n{d}", .{ number });
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
            try seed_to_soil_map.put(range, mappedRange);
        }

        // Soil → Fertilizer
        if (std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try soil_to_fertilizer_map.put(range, mappedRange);
        }

        // Fertilizer → Water
        if (std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try fertilizer_to_water_map.put(range, mappedRange);
        }

        // Water → Light
        if (std.mem.eql(u8, current_map, "water-to-light map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try water_to_light_map.put(range, mappedRange);
        }

        // Light → Temperature
        if (std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try light_to_temperature_map.put(range, mappedRange);
        }

        // Temperature → Humidity
        if (std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try temperature_to_humidity_map.put(range, mappedRange);
        }

        // Humidity → Location
        if (std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            const dst_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u64, row_it.next().?, 10);
            const range = Range{ .start = src_range, .end = src_range + range_len };
            const mappedRange = MapRange{ .dest_range_start = dst_range, .range_length = range_len };
            try humidity_to_location_map.put(range, mappedRange);
        }
    }

    var locations = std.ArrayList(u64).init(allocator);
    for (seeds_list.items) |seed| {
        const t = try std.Thread.spawn(.{}, resolveChain, .{ seed, &locations });
        t.join();
    }

    var lowest: u64 = locations.items[0];
    for (1..locations.items.len) |i| {
        if (locations.items[i] < lowest) {
            lowest = locations.items[i];
        }
    }

    const time = sw.stop();

    std.debug.print("\n\nResult:\n{d}\nTime: {d:3} ms\n", .{lowest, time});
}
