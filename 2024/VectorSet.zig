const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

pub fn VectorSet(comptime size: usize, comptime T: type) type {
    return struct {
        const VectorSetHashMap = AutoHashMap(@Vector(size, T), void);
        const Iterator = VectorSetHashMap.KeyIterator;

        const Self = @This();

        hash_map: VectorSetHashMap,

        pub fn init(a: Allocator) VectorSet(size, T) {
            return .{ .hash_map = VectorSetHashMap.init(a) };
        }

        pub fn deinit(self: *VectorSet) void {
            var it = self.hash_map.keyIterator();
            while (it.next()) |key_ptr| {
                self.hash_map.allocator.free(key_ptr.*);
            }
        }

        pub fn insert(self: *VectorSet(size, T), value: @Vector(size, T)) !void {
            const gop = try self.hash_map.getOrPut(value);
            if (!gop.found_existing) {
                var new_vec: @Vector(size, T) = @splat(0);
                inline for (0..size) |i| new_vec[i] = value[i];
                gop.key_ptr.* = new_vec;
            }
        }

        pub fn remove(self: *VectorSet(size, T), value: @Vector(size, T)) bool {
            return self.hash_map.remove(value);
        }

        pub fn contains(self: VectorSet(size, T), value: @Vector(size, T)) bool {
            return self.hash_map.contains(value);
        }

        pub fn getIndex(self: VectorSet(size, T), idx: usize) @Vector(size, T) {
            var it = self.hash_map.keyIterator();
            if (idx == 0) return it.next().?.*;
            for (0..idx) |_| {
                _ = it.next().?;
            }
            return it.next().?.*;
        }

        pub fn count(self: *const VectorSet(size, T)) usize {
            return self.hash_map.count();
        }

        pub fn iterator(self: *const VectorSet(size, T)) Iterator {
            return self.hash_map.keyIterator();
        }
    };
}
