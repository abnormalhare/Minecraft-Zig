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
    t: *Tesselator,

    pub var rebuiltThisFrame: i32 = 0;
    pub var updates: i32 = 0;

    pub fn new(level: *Level, x0: i32, y0: i32, z0: i32, x1: i32, y1: i32, z1: i32) !*Chunk {
        const c: *Chunk = try allocator.create(Chunk);
        c.t = try allocator.create(Tesselator);
        c.level = level;
        c.x0 = x0; c.y0 = y0; c.z0 = z0;
        c.x1 = x1; c.y1 = y1; c.z1 = z1;
        c.aabb = AABB{
            .x0 = @floatFromInt(x0),
            .y0 = @floatFromInt(y0),
            .z0 = @floatFromInt(z0),
            .x1 = @floatFromInt(x1),
            .y1 = @floatFromInt(y1),
            .z1 = @floatFromInt(z1)
        };
        c.lists = @intCast(GL.glGenLists(2));
        return c;
    }

    fn rebuild(self: *Chunk, layer: i32) void {
        if (Chunk.rebuiltThisFrame == 2) return;

        self.dirty = false;
        Chunk.updates += 1;
        Chunk.rebuiltThisFrame += 1;

        GL.glNewList(@intCast(self.lists + layer), GL.GL_COMPILE);
        GL.glEnable(GL.GL_TEXTURE_2D);
        GL.glBindTexture(GL.GL_TEXTURE_2D, @intCast(self.texture));

        self.t.init();

        var tiles: i32 = 0;
        for (@intCast(self.x0)..@intCast(self.x1)) |x| {
            for (@intCast(self.y0)..@intCast(self.y1)) |y| {
                for (@intCast(self.z0)..@intCast(self.z1)) |z| {
                    const tex: i32 = if (y == @divFloor(self.level.depth * 2, 3)) 0 else 1;
                    tiles += 1;
                    if (tex == 0) {
                        Tiles.rock.render(self.t, self.level, layer, @intCast(x), @intCast(y), @intCast(z));
                    } else {
                        Tiles.grass.render(self.t, self.level, layer, @intCast(x), @intCast(y), @intCast(z));
                    }
                }
            }
        }
        self.t.flush();
        GL.glDisable(GL.GL_TEXTURE_2D);
        GL.glEndList();
    }

    pub fn render(self: *Chunk, layer: i32) void {
        if (self.dirty) {
            self.rebuild(0);
            self.rebuild(1);
        }
        GL.glCallList(@intCast(self.lists + layer));
    }

    pub fn setDirty(self: *Chunk) void {
        self.dirty = true;
    }
};
