const std = @import("std");
const allocator = @import("../root.zig").allocator;
const GL = @import("glfw3");

const Level = @import("Level.zig").Level;
const Chunk = @import("Chunk.zig").Chunk;
const Tesselator = @import("Tesselator.zig").Tesselator;
const LevelListener = @import("LevelListener.zig").LevelListener;
const Frustum = @import("Frustum.zig").Frustum;
const Player = @import("../Player.zig").Player;
const AABB = @import("../phys/AABB.zig").AABB;
const HitResult = @import("../HitResult.zig").HitResult;
const Tiles = @import("Tile.zig");

const CHUNK_SIZE: i32 = 16;

pub const LevelRenderer = struct {
    _levelListener: LevelListener,
    level: *Level,
    chunks: []Chunk,
    xChunks: i32,
    yChunks: i32,
    zChunks: i32,
    t: *Tesselator,

    pub fn new(level: *Level) !*LevelRenderer {
        const lr: *LevelRenderer = try allocator.create(LevelRenderer);
        lr.t = try allocator.create(Tesselator);
        lr.level = level;
        lr.xChunks = @divFloor(level.width, CHUNK_SIZE);
        lr.yChunks = @divFloor(level.depth, CHUNK_SIZE);
        lr.zChunks = @divFloor(level.height, CHUNK_SIZE);
        lr.chunks = try allocator.alloc(Chunk, @as(usize, @intCast(lr.xChunks * lr.yChunks * lr.zChunks)));
        lr._levelListener.base = lr;
        lr._levelListener.tileChanged = tileChanged;
        lr._levelListener.lightColumnChanged = lightColumnChanged;
        lr._levelListener.allChanged = allChanged;
        try level.addListener(&lr._levelListener);

        for (0..@intCast(lr.xChunks)) |x| {
            for (0..@intCast(lr.yChunks)) |y| {
                for (0..@intCast(lr.zChunks)) |z| {
                    const x0: i32 = @as(i32, @intCast(x)) * 16;
                    const y0: i32 = @as(i32, @intCast(y)) * 16;
                    const z0: i32 = @as(i32, @intCast(z)) * 16;
                    var x1: i32 = @as(i32, @intCast(x + 1)) * 16;
                    var y1: i32 = @as(i32, @intCast(y + 1)) * 16;
                    var z1: i32 = @as(i32, @intCast(z + 1)) * 16;

                    if (x1 > level.width)  x1 = level.width;
                    if (y1 > level.depth)  y1 = level.depth;
                    if (z1 > level.height) z1 = level.height;

                    const chunk: *Chunk = try Chunk.new(
                        level, x0, y0, z0, x1, y1, z1,
                    );
                    lr.chunks[(x + y * @as(usize, @intCast(lr.xChunks))) * @as(usize, @intCast(lr.zChunks)) + z] = chunk.*;
                }
            }
        }

        return lr;
    }

    pub fn render(self: *LevelRenderer, player: *Player, layer: i32) void {
        Chunk.rebuiltThisFrame = 0;
        const frustum: *Frustum = Frustum.getFrustum();
        for (self.chunks) |*i| {
            if (frustum.cubeInFrustumA(i.aabb)) {
                i.render(layer);
            }
        }
        _ = player;
    }

    pub fn pick(self: *LevelRenderer, player: *Player) void {
        const r: f32 = 3.0;
        const box: AABB = player.bb.grow(r, r, r);
        const x0: usize = @intFromFloat(box.x0);
        const x1: usize = @intFromFloat(box.x1 + 1.0);
        const y0: usize = @intFromFloat(box.y0);
        const y1: usize = @intFromFloat(box.y1 + 1.0);
        const z0: usize = @intFromFloat(box.z0);
        const z1: usize = @intFromFloat(box.z1 + 1.0);

        GL.glInitNames();
        for (x0..x1) |x| {
            GL.glPushName(@intCast(x));
            for (y0..y1) |y| {
                GL.glPushName(@intCast(y));
                for (z0..z1) |z| {
                    GL.glPushName(@intCast(z));
                    if (self.level.isSolidTile(@intCast(x), @intCast(y), @intCast(z))) {
                        GL.glPushName(0);
                        for (0..6) |i| {
                            GL.glPushName(@intCast(i));
                            self.t.init();
                            Tiles.rock.renderFace(self.t, @intCast(x), @intCast(y), @intCast(z), @intCast(i));
                            self.t.flush();
                            GL.glPopName();
                        }
                        GL.glPopName();
                    }
                    GL.glPopName();
                }
                GL.glPopName();
            }
            GL.glPopName();
        }
    }

    pub fn renderHit(self: *LevelRenderer, h: *HitResult) void {
        GL.glEnable(GL.GL_BLEND);
        GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
        const currTime: f64 = @floatFromInt(std.time.milliTimestamp());
        GL.glColor4f(1.0, 1.0, 1.0, @as(f32, @floatCast(std.math.sin(currTime / 100.0))) * 0.2 + 0.4);
        self.t.init();
        Tiles.rock.renderFace(self.t, h.x, h.y, h.z, h.f);
        self.t.flush();
        GL.glDisable(GL.GL_BLEND);
    }

    pub fn setDirty(self: *LevelRenderer, x0: i32, y0: i32, z0: i32, x1: i32, y1: i32, z1: i32) void {
        var _x0: i32 = @divFloor(x0, 16); var _x1: i32 = @divFloor(x1, 16);
        var _y0: i32 = @divFloor(y0, 16); var _y1: i32 = @divFloor(y1, 16);
        var _z0: i32 = @divFloor(z0, 16); var _z1: i32 = @divFloor(z1, 16);

        if (_x0 < 0) _x0 = 0;
        if (_y0 < 0) _y0 = 0;
        if (_z0 < 0) _z0 = 0;
        if (_x1 >= self.xChunks) _x1 = self.xChunks - 1;
        if (_y1 >= self.yChunks) _y1 = self.yChunks - 1;
        if (_z1 >= self.zChunks) _z1 = self.zChunks - 1;

        for (@intCast(_x0)..@intCast(_x1 + 1)) |x| {
            for (@intCast(_y0)..@intCast(_y1 + 1)) |y| {
                for (@intCast(_z0)..@intCast(_z1 + 1)) |z| {
                    self.chunks[(x + y * @as(usize, @intCast(self.xChunks))) * @as(usize, @intCast(self.zChunks)) + z].setDirty();
                }
            }
        }
    }

    pub fn tileChanged(self: *LevelListener, x: i32, y: i32, z: i32) void {
        const base: *LevelRenderer = @ptrCast(@alignCast(self.base));
        base.setDirty(x - 1, y - 1, z - 1, x + 1, y + 1, z + 1);
    }

    pub fn lightColumnChanged(self: *LevelListener, x: i32, y0: i32, y1: i32, z: i32) void {
        const base: *LevelRenderer = @ptrCast(@alignCast(self.base));
        base.setDirty(x - 1, y0 - 1, z - 1, x + 1, y1 + 1, z + 1);
    }

    pub fn allChanged(self: *LevelListener) void {
        const base: *LevelRenderer = @ptrCast(@alignCast(self.base));
        base.setDirty(0, 0, 0, base.level.width, base.level.depth, base.level.height);
    }
};