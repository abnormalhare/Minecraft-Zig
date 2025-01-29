const std = @import("std");
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
    t: Tesselator,

    fn new(level: *Level) LevelRenderer {
        const lr = LevelRenderer{
            .t = Tesselator{},
            .level = level,
            .xChunks = level.width / 16,
            .yChunks = level.depth / 16,
            .zChunks = level.height / 16,
        };
        lr.chunks = [_]Chunk{} ** (lr.xChunks * lr.yChunks * lr.zChunks);
        lr._levelListener.base = lr;
        lr._levelListener.tileChanged = lr.tileChanged;
        lr._levelListener.lightColumnChanged = lr.lightColumnChanged;
        lr._levelListener.allChanged = lr.allChanged;
        level.addListener(&lr.LevelListener);

        var x: i32 = 0;
        var y: i32 = 0;
        var z: i32 = 0;
        while (x < lr.xChunks) : (x += 1) {
            while (y < lr.yChunks) : (y += 1) {
                while (z < lr.zChunks) : (z += 1) {
                    const x0: i32 = x * 16;
                    const y0: i32 = y * 16;
                    const z0: i32 = z * 16;
                    const x1: i32 = (x + 1) * 16;
                    const y1: i32 = (y + 1) * 16;
                    const z1: i32 = (z + 1) * 16;

                    if (x1 > level.width)  x1 = level.width;
                    if (y1 > level.depth)  y1 = level.depth;
                    if (z1 > level.height) z1 = level.height;

                    lr.chunks[(x + y * lr.xChunks) * lr.zChunks + z] = Chunk.new(
                        level, x0, y0, z0, x1, y1, z1,
                    );
                }
            }
        }
    }

    fn render(self: *LevelRenderer, player: Player, layer: i32) void {
        Chunk.rebuiltThisFrame = 0;
        const frustum: Frustum = Frustum.getFrustum();
        for (self.chunks) |i| {
            if (frustum.cubeInFrustum(i.aabb)) {
                i.render(layer);
            }
        }
        player;
    }

    fn pick(self: *LevelRenderer, player: Player) void {
        const r: f32 = 3.0;
        const box: AABB = player.bb.grow(r, r, r);
        const x0: i32 = box.x0;
        const x1: i32 = box.x1 + 1.0;
        const y0: i32 = box.y0;
        const y1: i32 = box.y1 + 1.0;
        const z0: i32 = box.z0;
        const z1: i32 = box.z1 + 1.0;

        var x: i32 = x0;
        var y: i32 = y0;
        var z: i32 = z0;
        GL.glInitNames();
        while (x < x1) : (x += 1) {
            GL.glPushName(x);
            while (y < y1) : (y += 1) {
                GL.glPushName(y);
                while (z < z1) : (z += 1) {
                    GL.glPushName(z);
                    if (self.level.isSolidTile(x, y, z)) {
                        const i: i32 = 0;
                        GL.glPushName(0);
                        while (i < 6) : (i += 1) {
                            GL.glPushName(i);
                            self.t.init();
                            Tiles.rock.renderFace(self.t, x, y, z, i);
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

    fn renderHit(self: *LevelRenderer, h: HitResult) void {
        GL.glEnable(GL.GL_BLEND);
        GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
        GL.glColor4f(1.0, 1.0, 1.0, f32(std.math.sin(std.time.milliTimestamp() / 100.0)) * 0.2 + 0.4);
        self.t.init();
        Tiles.rock.renderFace(self.t, h.x, h.y, h.z, h.f);
        self.t.flush();
        GL.glDisable(GL.GL_BLEND);
    }

    fn setDirty(self: *LevelRenderer, x0: i32, y0: i32, z0: i32, x1: i32, y1: i32, z1: i32) void {
        x0 /= 16; x1 /= 16;
        y0 /= 16; y1 /= 16;
        z0 /= 16; z1 /= 16;

        if (x0 < 0) x0 = 0;
        if (y0 < 0) y0 = 0;
        if (z0 < 0) z0 = 0;
        if (x1 >= self.xChunks) x1 = self.xChunks - 1;
        if (y1 >= self.yChunks) y1 = self.yChunks - 1;
        if (z1 >= self.zChunks) z1 = self.zChunks - 1;

        var x: i32 = x0;
        var y: i32 = y0;
        var z: i32 = z0;
        while (x <= x1) : (x += 1) {
            while (y <= y1) : (y += 1) {
                while (z <= z1) : (z += 1) {
                    self.chunks[(x + y * self.xChunks) * self.zChunks + z].setDirty();
                }
            }
        }
    }

    fn tileChanged(self: *LevelListener, x: i32, y: i32, z: i32) void {
        self.base.setDirty(x - 1, y - 1, z - 1, x + 1, y + 1, z + 1);
    }

    fn lightColumnChanged(self: *LevelListener, x: i32, y0: i32, y1: i32, z: i32) void {
        self.base.setDirty(x - 1, y0 - 1, z - 1, x + 1, y1 + 1, z + 1);
    }

    fn allChanged(self: *LevelListener) void {
        self.base.setDirty(0, 0, 0, self.base.level.width, self.base.level.depth, self.base.level.height);
    }
};