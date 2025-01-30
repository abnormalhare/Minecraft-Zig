const std = @import("std");
const LevelListener = @import("LevelListener.zig").LevelListener;
const AABB = @import("../phys/AABB.zig").AABB;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const Level = struct {
    width: i32, height: i32, depth: i32,

    blocks: []u8,
    lightDepths: []i32,

    levelListeners: std.ArrayList(*LevelListener),

    pub fn new(w: i32, h: i32, d: i32) !*Level {
        const l: *Level = try allocator.create(Level);

        const _w: usize = @intCast(w);
        const _h: usize = @intCast(h);
        const _d: usize = @intCast(d);

        l.width = w;
        l.height = h;
        l.depth = d;
        l.blocks = try allocator.alloc(u8, _w * _h * _d);
        l.lightDepths = try allocator.alloc(i32, _w * _h);
        l.levelListeners = std.ArrayList(*LevelListener).init(std.heap.page_allocator);

        for (0.._w) |x| {
            for (0.._d) |y| {
                for (0.._h) |z| {
                    const i: usize = (y * @as(usize, @intCast(l.height)) + z) * @as(usize, @intCast(l.width)) + x;
                    l.blocks[i] = if (y <= @divFloor(d * 2, 3)) 1 else 0;
                }
            }
        }

        l.calcLightDepths(0, 0, w, h);
        l.load();

        return l;
    }

    pub fn load(self: *Level) void {
        const dis = try std.fs.cwd().openFile("level.dat", .{});
        defer dis.close();

        dis.readAll(self.blocks);
        self.calcLightDepths(0, 0, self.width, self.height);
        
        for (self.levelListeners.items) |listener| {
            listener.allChanged();
        }
    }

    pub fn save(self: *Level) void {
        const dos = try std.fs.cwd().openFile("level.dat", .{});
        defer dos.close();

        dos.write(self.blocks);
    }

    pub fn calcLightDepths(self: *Level, x0: i32, y0: i32, x1: i32, y1: i32) void {
        for (0..@as(usize, @intCast(x0 + x1))) |x| {
            for (0..@as(usize, @intCast(y0 + y1))) |z| {
                const oldDepth: i32 = self.lightDepths[x + z * self.width];
                var y: i32 = self.depth - 1;

                while (y > 0 and !self.isLightBlocker(x, y, z)) {
                    y -= 1;
                }

                self.lightDepths[x + z * self.width] = y;
                if (oldDepth != y) {
                    const y10: i32 = if (oldDepth < y) oldDepth else y;
                    const y11: i32 = if (oldDepth > y) oldDepth else y;
                    for (self.levelListeners.items) |listener| {
                        listener.lightColumnChanged(x, z, y10, y11);
                    }
                }
            }
        }
    }

    pub fn addListener(self: *Level, levelListener: *LevelListener) void {
        self.levelListeners.append(levelListener);
    }

    pub fn removeListener(self: *Level, levelListener: *LevelListener) void {
        const llPtr: *LevelListener = levelListener;
        var i: i32 = 0;
        while (llPtr != self.levelListeners.items[i]) : (i += 1) {}
        self.levelListeners.orderedRemove(i);
    }

    pub fn isTile(self: *Level, x: i32, y: i32, z: i32) bool {
        if (x < 0 or y < 0 or z < 0 or x >= self.width or y >= self.depth or z >= self.height) {
            return false;
        }
        
        return self.blocks[(y * self.height + z) * self.width + x] == 1;
    }

    pub fn isSolidTile(self: *Level, x: i32, y: i32, z: i32) bool {
        return self.isTile(x, y, z);
    }

    pub fn isLightBlocker(self: *Level, x: i32, y: i32, z: i32) bool {
        return self.isSolidTile(x, y, z);
    }

    pub fn getCubes(self: *Level, aABB: AABB) std.ArrayList(AABB) {
        const aABBs = std.ArrayList(AABB).init(std.heap.page_allocator);

        var x0: i32 = aABB.x0;
        var x1: i32 = aABB.x1 + 1.0;
        var y0: i32 = aABB.y0;
        var y1: i32 = aABB.y1 + 1.0;
        var z0: i32 = aABB.z0;
        var z1: i32 = aABB.z1 + 1.0;

        if (x0 < 0) x0 = 0;
        if (y0 < 0) y0 = 0;
        if (z0 < 0) z0 = 0;
        if (x1 > self.width)  x1 = self.width;
        if (y1 > self.depth)  y1 = self.depth;
        if (z1 > self.height) z1 = self.height;

        for (x0..x1) |x| {
            for (y0..y1) |y| {
                for (z0..z1) |z| {
                    if (self.isSolidTile(x, y, z)) {
                        aABBs.append(AABB{.x0 = x, .y0 = y, .z0 = z, .x1 = x + 1, .y1 = y + 1, .z1 = z + 1});
                    }
                }
            }
        }

        return aABBs;
    }

    pub fn getBrightness(self: *Level, x: i32, y: i32, z: i32) f32 {
        const dark: f32 = 0.8;
        const light: f32 = 1.0;

        if (x < 0 or y < 0 or z < 0 or x >= self.width or y >= self.depth or z >= self.height) {
            return light;
        }
        if (y < self.lightDepths[x + z * self.width]) {
            return dark;
        }
        return light;
    }

    pub fn setTile(self: *Level, x: i32, y: i32, z: i32, typ: i32) void {
        if (x < 0 or y < 0 or z < 0 or x >= self.width or y >= self.depth or z >= self.height) {
            return;
        }
        self.blocks[(y * self.height + z) * self.width + x] = typ;
        self.calcLightDepths(x, z, 1, 1);

        for (self.levelListeners.items) |listener| {
            listener.tileChanged(x, y, z);
        }
    }
};