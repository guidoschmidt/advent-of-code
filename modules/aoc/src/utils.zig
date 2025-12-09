const std = @import("std");
const types = @import("types.zig");

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

pub fn getTemplate() []const u8 {
    return @embedFile("template.zig");
}
