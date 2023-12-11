const std = @import("std");

const MapRange = struct {
    dest_range_start: u32,
    range_length: u32
};

pub fn main() !void {
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    var seeds_list = std.ArrayList(u32).init(allocator);
    var seed_to_soil_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var soil_to_fertilizer_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var fertilizer_to_water_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var water_to_light_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var light_to_temperature_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var temperature_to_humidity_map = std.AutoHashMap(u32, MapRange).init(allocator);
    var humidity_to_location_map = std.AutoHashMap(u32, MapRange).init(allocator);

    const data = @embedFile("data/day5.txt");
    var parts_it = std.mem.tokenize(u8, data, "\n");
    var current_map: []u8 = @constCast(parts_it.next().?);
    while(parts_it.next()) |part| {
        if (std.mem.containsAtLeast(u8, part, 1, ":")) {
            current_map = @constCast(part);
            continue;
        }

        // std.debug.print("\n{s} <-- {s}", .{ current_map, part });
        var values_it = std.mem.tokenize(u8, part, " ");

        if (std.mem.eql(u8, part, "seeds:")) {
            while(values_it.next()) |v| {
                const number = try std.fmt.parseInt(u32, v, 10);
                try seeds_list.append(number);
            }
        }
        if(std.mem.eql(u8, current_map, "seed-to-soil map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try seed_to_soil_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "soil-to-fertilizer map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try soil_to_fertilizer_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "fertilizer-to-water map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try fertilizer_to_water_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "water-to-light map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try water_to_light_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "light-to-temperature map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try light_to_temperature_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "temperature-to-humidity map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try temperature_to_humidity_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
        if(std.mem.eql(u8, current_map, "humidity-to-location map:")) {
            const dst_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const src_range = try std.fmt.parseInt(u32, values_it.next().?, 10);
            const range_len = try std.fmt.parseInt(u32, values_it.next().?, 10);
            try humidity_to_location_map.put(src_range, MapRange{
                .dest_range_start = dst_range,
                .range_length = range_len
            });
        }
    }
}
