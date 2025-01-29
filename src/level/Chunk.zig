const std = @import("std");

const GL = @import("glfw3");
const AABB = @import("../phys/AABB.zig").AABB;
const Level = @import("Level.zig").Level;
const Textures = @import("../Textures.zig").Textures;
const Tesselator = @import("Tesselator.zig").Tesselator;
const Tiles = @import("Tile.zig");
const Tile = Tiles.Tile;

const allocator = std.heap.page_allocator;

pub const Chunk = struct {
    aabb: AABB,
    level: *Level,

    x0: i32,
    y0: i32,
    z0: i32,
    x1: i32,
    y1: i32,
    z1: i32,

    dirty: bool = true,
    lists: i32 = -1,
    texture: i32 = Textures.loadTexture("/terrain.png", GL.GL_NEAREST),
    t: Tesselator = Tesselator{},

    const rebuiltThisFrame: i32 = 0;
    const updates: i32 = 0;

    fn new(level: *Level, x0: i32, y0: i32, z0: i32, x1: i32, y1: i32, z1: i32) *Chunk {
        const c: *Chunk = try allocator.alloc(Chunk, 1);
        c.level = level;
        c.x0 = x0; c.y0 = y0; c.z0 = z0;
        c.x1 = x1; c.y1 = y1; c.z1 = z1;
        c.aabb = AABB{ .x0 = x0, .y0 = y0, .z0 = z0, .x1 = x1, .y1 = y1, .z1 = z1 };
        c.lists = GL.glGenLists(2);
        return c;
    }

    fn rebuild(self: *Chunk, layer: i32) void {
        if (Chunk.rebuiltThisFrame == 2) return;

        self.dirty = false;
        Chunk.updates += 1;
        Chunk.rebuiltThisFrame += 1;

        GL.glNewList(self.lists + layer, GL.GL_COMPILE);
        GL.glEnable(GL.GL_TEXTURE_2D);
        GL.glBindTexture(GL.GL_TEXTURE_2D, self.texture);

        self.t.init();

        var tiles: i32 = 0;
        var x: i32 = self.x0;
        var y: i32 = self.y0;
        var z: i32 = self.z0;
        while (x < self.x1) : (x += 1) {
            while (y < self.y1) : (y += 1) {
                while (z < self.z1) : (z += 1) {
                    const tex: i32 = if (y == self.level.depth * 2 / 3) 0 else 1;
                    tiles += 1;
                    if (tex == 0) {
                        Tiles.rock.render(self.t, self.level, layer, x, y, z);
                    } else {
                        Tiles.grass.render(self.t, self.level, layer, x, y, z);
                    }
                }
            }
        }
        self.t.flush();
        GL.glDisable(GL.GL_TEXTURE_2D);
        GL.glEndList();
    }

    fn render(self: *Chunk, layer: i32) void {
        if (self.dirty) {
            self.rebuild(0);
            self.rebuild(1);
        }
        GL.glCallList(self.lists + layer);
    }

    fn setDirty(self: *Chunk) void {
        self.dirty = true;
    }
};
