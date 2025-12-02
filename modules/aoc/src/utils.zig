const std = @import("std");
const zeit = @import("zeit");

pub fn blockAskForNext() void {
    step: {
        var reader_buffer: [10]u8 = undefined;
        var reader = std.fs.File.stdin().readerStreaming(&reader_buffer);
        std.debug.print("\n\n→ Step: [Enter]", .{});
        var writter_buffer: [10]u8 = undefined;
        var writer = std.fs.File.stdout().writerStreaming(&writter_buffer);
        _ = reader.interface.streamDelimiter(&writer.interface, '\n') catch return;
        _ = reader.interface.takeByte() catch return;
        break :step;
    }
}

pub fn getToday() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();
    const local = try zeit.local(allocator, &env);
    const now = try zeit.instant(.{});
    const now_local = now.in(&local);
    const dt = now_local.time();
    std.debug.print("{}", .{dt});
}

pub fn getTemplate() []const u8 {
    return @embedFile("template.zig");
}
