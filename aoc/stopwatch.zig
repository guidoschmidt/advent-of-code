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
    const elapsed: u64 = timer.read();
    return elapsed;
}
