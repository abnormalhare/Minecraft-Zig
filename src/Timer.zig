const std = @import("std");
const allocator = @import("root.zig").allocator;

const NS_PER_SECOND: i64 = 1000000000;
const MAX_NS_PER_UPDATE: i64 = 1000000000;
const MAX_TICKS_PER_UPDATE: i32 = 100;

pub const Timer = struct {
    ticksPerSecond: f32,
    lastTime: i64,
    ticks: i32,
    a: f32,
    timeScale: f32 = 1.0,
    fps: f32 = 0.0,
    passedTime: f32 = 0.0,

    pub fn new(ticksPerSecond: f32) !*Timer {
        const t: *Timer = try allocator.create(Timer);
        t.ticksPerSecond = ticksPerSecond;
        t.lastTime = @intCast(std.time.nanoTimestamp());
        t.timeScale = 1.0;
        t.fps = 0.0;
        t.passedTime = 0.0;

        return t;
    }

    pub fn advanceTime(self: *Timer) void {
        const now: i64 = @intCast(std.time.nanoTimestamp());
        var passedNs: i64 = now - self.lastTime;
        self.lastTime = now;

        if (passedNs < 0) passedNs = 0;
        if (passedNs > MAX_NS_PER_UPDATE) passedNs = MAX_NS_PER_UPDATE;


        self.fps = NS_PER_SECOND / @as(f32, @floatFromInt(passedNs));
        self.passedTime += @as(f32, @floatFromInt(passedNs)) * self.timeScale * self.ticksPerSecond / NS_PER_SECOND;

        self.ticks = @intFromFloat(self.passedTime);
        if (self.ticks > MAX_TICKS_PER_UPDATE) self.ticks = MAX_TICKS_PER_UPDATE;
        self.passedTime -= @floatFromInt(self.ticks);
        self.a = self.passedTime;
    }
};
