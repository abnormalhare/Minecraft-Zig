const std = @import("std");
const allocator = @import("root.zig").allocator;

pub const HitResult = struct {
    x: i32, y: i32, z: i32,
    o: i32, f: i32,

    pub fn new(x: i32, y: i32, z: i32, o: i32, f: i32) ?*HitResult {
        const h: *HitResult = allocator.create(HitResult) catch |err| switch (err) {
            error.OutOfMemory => {
                std.debug.print("Failed to allocate memory to HitResult", .{});
                std.process.exit(1);
            }
        };

        h.x = x;
        h.y = y;
        h.z = z;
        h.o = o;
        h.f = f;

        return h;
    }
};