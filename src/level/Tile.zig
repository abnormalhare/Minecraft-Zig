const Tesselator = @import("Tesselator.zig").Tesselator;
const Level = @import("Level.zig").Level;

pub const Tile = struct {
    tex: i32 = 0,

    pub fn render(self: *Tile, t: Tesselator, level: *Level, layer: i32, x: i32, y: i32, z: i32) void {
        const _u0: f32 = self.tex / 16.0;
        const _u1: f32 = _u0 + 0.0624375;
        const v0: f32 = 0.0;
        const v1: f32 = v0 + 0.0624375;
        const c1: f32 = 1.0;
        const c2: f32 = 0.8;
        const c3: f32 = 0.6;

        const x0: f32 = x + 0.0;
        const x1: f32 = x + 1.0;
        const y0: f32 = y + 0.0;
        const y1: f32 = y + 1.0;
        const z0: f32 = z + 0.0;
        const z1: f32 = z + 1.0;

        if (!level.isSolidTile(x, y - 1, z)) {
            const br: f32 = level.getBrightness(x, y - 1, z) * c1;
            if (((br == c1) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u0, v1);
                t.vertex(x0, y0, z1);
                t.tex(_u0, v0);
                t.vertex(x0, y0, z0);
                t.tex(_u1, v0);
                t.vertex(x1, y0, z0);
                t.tex(_u1, v1);
                t.vertex(x1, y0, z1);
            }
        }

        if (!level.isSolidTile(x, y + 1, z)) {
            const br: f32 = level.getBrightness(x, y, z) * c1;
            if (((br == c1) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u1, v1);
                t.vertex(x1, y1, z1);
                t.tex(_u1, v0);
                t.vertex(x1, y1, z0);
                t.tex(_u0, v0);
                t.vertex(x0, y1, z0);
                t.tex(_u0, v1);
                t.vertex(x0, y1, z1);
            }
        }

        if (!level.isSolidTile(x, y, z - 1)) {
            const br: f32 = level.getBrightness(x, y, z - 1) * c2;
            if (((br == c2) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u1, v0);
                t.vertex(x0, y1, z0);
                t.tex(_u0, v0);
                t.vertex(x1, y1, z0);
                t.tex(_u0, v1);
                t.vertex(x1, y0, z0);
                t.tex(_u1, v1);
                t.vertex(x0, y0, z0);
            }
        }

        if (!level.isSolidTile(x, y, z + 1)) {
            const br: f32 = level.getBrightness(x, y, z + 1) * c2;
            if (((br == c2) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u0, v0);
                t.vertex(x0, y1, z1);
                t.tex(_u0, v1);
                t.vertex(x0, y0, z1);
                t.tex(_u1, v1);
                t.vertex(x1, y0, z1);
                t.tex(_u1, v0);
                t.vertex(x1, y1, z1);
            }
        }

        if (!level.isSolidTile(x - 1, y, z)) {
            const br: f32 = level.getBrightness(x - 1, y, z) * c3;
            if (((br == c3) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u1, v0);
                t.vertex(x0, y1, z1);
                t.tex(_u0, v0);
                t.vertex(x0, y1, z0);
                t.tex(_u0, v1);
                t.vertex(x0, y0, z0);
                t.tex(_u1, v1);
                t.vertex(x0, y0, z1);
            }
        }
        
        if (!level.isSolidTile(x + 1, y, z)) {
            const br: f32 = level.getBrightness(x + 1, y, z) * c3;
            if (((br == c3) ^ (layer == 1)) != 0) {
                t.color(br, br, br);
                t.tex(_u0, v1);
                t.vertex(x1, y0, z1);
                t.tex(_u1, v1);
                t.vertex(x1, y0, z0);
                t.tex(_u1, v0);
                t.vertex(x1, y1, z0);
                t.tex(_u0, v0);
                t.vertex(x1, y1, z1);
            }
        }
    }

    pub fn renderFace(self: *Tile, t: Tesselator, x: i32, y: i32, z: i32, face: i32) void {
        const x0: f32 = x + 0.0;
        const x1: f32 = x + 1.0;
        const y0: f32 = y + 0.0;
        const y1: f32 = y + 1.0;
        const z0: f32 = z + 0.0;
        const z1: f32 = z + 1.0;

        if (face == 0) {
            t.vertex(x0, y0, z1);
            t.vertex(x0, y0, z0);
            t.vertex(x1, y0, z0);
            t.vertex(x1, y0, z1);
        } 
        if (face == 1) {
            t.vertex(x1, y1, z1);
            t.vertex(x1, y1, z0);
            t.vertex(x0, y1, z0);
            t.vertex(x0, y1, z1);
        } 
        if (face == 2) {
            t.vertex(x0, y1, z0);
            t.vertex(x1, y1, z0);
            t.vertex(x1, y0, z0);
            t.vertex(x0, y0, z0);
        } 
        if (face == 3) {
            t.vertex(x0, y1, z1);
            t.vertex(x0, y0, z1);
            t.vertex(x1, y0, z1);
            t.vertex(x1, y1, z1);
        } 
        if (face == 4) {
            t.vertex(x0, y1, z1);
            t.vertex(x0, y1, z0);
            t.vertex(x0, y0, z0);
            t.vertex(x0, y0, z1);
        } 
        if (face == 5) {
            t.vertex(x1, y0, z1);
            t.vertex(x1, y0, z0);
            t.vertex(x1, y1, z0);
            t.vertex(x1, y1, z1);
        }

        self;
    }
};

pub const rock:  Tile = Tile{ .tex = 0 };
pub const grass: Tile = Tile{ .tex = 1 };