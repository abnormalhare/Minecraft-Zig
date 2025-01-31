const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const HitResult = struct {
    x: i32, y: i32, z: i32,
    o: i32, f: i32,

    pub fn new(x: i32, y: i32, z: i32, o: i32, f: i32) !*HitResult {
        const h: *HitResult = try allocator.create(HitResult);

        h.x = x;
        h.y = y;
        h.z = z;
        h.o = o;
        h.f = f;

        return h;
    }
};