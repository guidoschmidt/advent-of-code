const std = @import("std");
const time = std.time;
const Timer = time.Timer;

var timer: Timer = undefined;

pub fn start() void {
    timer = Timer.start() catch {
        unreachable;
    };
}

pub fn stop() u64 {
    const elapsed: f64 = @floatFromInt(timer.read()) ;
    return @intFromFloat(elapsed / time.ns_per_ms);
}
