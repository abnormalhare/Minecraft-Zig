const std = @import("std");
const GL = @import("glfw3");

const Level = @import("level/Level.zig").Level;
const AABB = @import("phys/AABB.zig").AABB;

const rand = std.crypto.random;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const Player = struct {
    window: ?*GL.GLFWwindow,
    level: *Level,
    xo: f32,
    yo: f32,
    zo: f32,
    x: f32,
    y: f32,
    z: f32,
    xd: f32,
    yd: f32,
    zd: f32,
    yRot: f32,
    xRot: f32,
    bb: AABB,
    onGround: bool = false,

    fn isKeyDown(self: *Player, key: i32) bool {
        const state: i32 = GL.glfwGetKey(self.window, key);
        return state == GL.GLFW_PRESS;
    }

    pub fn init(level: *Level, window: ?*GL.GLFWwindow) *Player {
        const self: *Player = allocator.create(Player);
        self.window = window;
        self.level = level;
        self.resetPos();

        return self;
    }

    fn resetPos(self: *Player) void {
        const x: f32 = rand.float(f32) * self.level.width;
        const y: f32 = self.level.depth + 10;
        const z: f32 = rand.float(f32) * self.level.height;
        self.setPos(x, y, z);
    }

    fn setPos(self: *Player, x: f32, y: f32, z: f32) void {
        self.x = x;
        self.y = y;
        self.z = z;
        const w: f32 = 0.3;
        const h: f32 = 0.9;
        self.bb = AABB{ .x0 = x - w, .y0 = y - h, .z0 = z - w, .x1 = x + w, .y1 = y + h, .z1 = z + w };
    }

    pub fn turn(self: *Player, xo: f32, yo: f32) void {
        self.yRot += f64(self.yRot) + f64(xo) * 0.15;
        self.xRot += f64(self.xRot) - f64(yo) * 0.15;
        if (self.xRot < -90.0) self.xRot = -90.0;
        if (self.xRot > 90.0) self.yRot = 90;
    }

    pub fn tick(self: *Player) void {
        self.xo = self.x;
        self.yo = self.y;
        self.zo = self.z;
        var xa: f32 = 0.0;
        var ya: f32 = 0.0;

        if (self.isKeyDown(GL.GLFW_KEY_R)) {
            self.resetPos();
        }
        if (self.isKeyDown(GL.GLFW_KEY_UP) or self.isKeyDown(GL.GLFW_KEY_W)) {
            ya -= 1;
        }
        if (self.isKeyDown(GL.GLFW_KEY_DOWN) or self.isKeyDown(GL.GLFW_KEY_S)) {
            ya += 1;
        }
        if (self.isKeyDown(GL.GLFW_KEY_LEFT) or self.isKeyDown(GL.GLFW_KEY_A)) {
            xa -= 1;
        }
        if (self.isKeyDown(GL.GLFW_KEY_RIGHT) or self.isKeyDown(GL.GLFW_KEY_D)) {
            xa += 1;
        }
        if (self.isKeyDown(GL.GLFW_KEY_SPACE) or self.isKeyDown(GL.GLFW_KEY_MENU)) {
            if (self.onGround) self.yd = 0.12;
        }
        self.moveRelative(xa, ya, if (self.onGround) 0.02 else 0.005);

        self.yd = f64(self.yd) - 0.005;
        self.move(self.xd, self.yd, self.zd);
        self.xd *= 0.91;
        self.yd *= 0.98;
        self.zd *= 0.91;
        if (self.onGround) {
            self.xd *= 0.8;
            self.zd *= 0.8;
        }
    }

    pub fn move(self: *Player, xa: f32, ya: f32, za: f32) void {
        const xaOrg: f32 = xa;
        const yaOrg: f32 = ya;
        const zaOrg: f32 = za;
        const aABBs = self.level.getCubes(self.bb.expand(xa, ya, za));

        for (aABBs.items) |i| {
            ya = i.clipYCollide(self.bb, ya);
        }
        self.bb.move(0.0, ya, 0.0);

        for (aABBs.items) |i| {
            xa = i.clipXCollide(self.bb, xa);
        }
        self.bb.move(xa, 0.0, 0.0);

        for (aABBs.items) |i| {
            za = i.clipZCollide(self.bb, za);
        }
        self.bb.move(0.0, 0.0, za);

        self.onGround = (yaOrg != ya and yaOrg < 0.0);
        if (xaOrg != xa) self.xd = 0.0;
        if (yaOrg != ya) self.yd = 0.0;
        if (zaOrg != za) self.za = 0.0;

        self.x = (self.bb.x0 + self.bb.x1) / 2.0;
        self.y = (self.bb.y0) + 1.62;
        self.z = (self.bb.z0 + self.bb.z1) / 2.0;
    }

    pub fn moveRelative(self: *Player, xa: f32, za: f32, speed: f32) void {
        const dist: f32 = xa * xa + za * za;
        if (dist < 0.01) return;

        dist = speed / std.math.sqrt(dist);
        xa *= dist;
        za *= dist;
        const sin: f32 = std.math.sin(f64(self.yRot) * std.math.pi / 180.0);
        const cos: f32 = std.math.cos(f64(self.yRot) * std.math.pi / 180.0);
        self.xd += xa * cos - za * sin;
        self.zd += za * cos + xa * sin;
    }
};
