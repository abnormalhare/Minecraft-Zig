const std = @import("std");
const GL = @import("glfw3");
const GLU = @cImport({
    @cInclude("C:/msys64/ucrt64/include/GL/glu.h");
});

const Level = @import("level/Level.zig").Level;
const Timer = @import("Timer.zig").Timer;
const LevelRenderer = @import("level/LevelRenderer.zig").LevelRenderer;
const Player = @import("Player.zig").Player;
const HitResult = @import("HitResult.zig").HitResult;
const Chunk = @import("level/Chunk.zig").Chunk;
const Frustum = @import("level/Frustum.zig").Frustum;

const FULLSCREEN_MODE: bool = false;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const RubyDung = struct {
    width: i32,
    height: i32,
    fogColor: [4]f32,
    timer: *Timer,
    level: *Level,
    levelRenderer: *LevelRenderer,
    player: *Player,
    hitResult: ?*HitResult = null,

    viewportBuffer: [16]i32,
    selectBuffer: [2000]u32,

    window: ?*GL.GLFWwindow,
    cursor: ?*GL.GLFWcursor,
    lastMouseX: f64 = 0.0,
    lastMouseY: f64 = 0.0,

    fn mouseButtonCallback(self: *RubyDung, window: *GL.GLFWwindow, button: i32, action: i32, mods: i32) void {
        if (button == GL.GLFW_MOUSE_BUTTON_RIGHT and action == GL.GLFW_PRESS) {
            if (self.hitResult != null) {
                self.level.setTile(self.hitResult.?.x, self.hitResult.?.y, self.hitResult.?.z, 0);
            }
        }
        if (button == GL.GLFW_MOUSE_BUTTON_LEFT and action == GL.GLFW_PRESS) {
            if (self.hitResult != null) {
                var x: i32 = self.hitResult.?.x;
                var y: i32 = self.hitResult.?.y;
                var z: i32 = self.hitResult.?.z;

                const f: i32 = self.hitResult.?.f;

                if (f == 0) y -= 1;
                if (f == 1) y += 1;
                if (f == 2) z -= 1;
                if (f == 3) z += 1;
                if (f == 4) x -= 1;
                if (f == 5) x += 1;

                self.level.setTile(x, y, z, 1);
            }
        }
        _ = window;
        _ = mods;
    }

    fn keyCallback(self: *RubyDung, window: *GL.GLFWwindow, key: i32, scancode: i32, action: i32, mods: i32) void {
        if (key == GL.GLFW_KEY_ESCAPE and action == GL.GLFW_PRESS) {
            self.level.save() catch |err| {
                if (err != error.CouldNotWriteImage) {
                    std.debug.print("Failed to save level\n", .{});
                }
            };
            GL.glfwSetWindowShouldClose(window, GL.GLFW_TRUE);
        }
        _ = scancode;
        _ = mods;
    }

    fn setDisplayMode(self: *RubyDung, width: i32, height: i32) void {
        if (GL.glfwInit() == 0) {
            std.debug.print("Failed to initialize GLFW\n", .{});
            std.process.exit(1);
        }

        GL.glfwWindowHint(GL.GLFW_CONTEXT_VERSION_MAJOR, 1);
        GL.glfwWindowHint(GL.GLFW_CONTEXT_VERSION_MINOR, 1);

        self.window = GL.glfwCreateWindow(width, height, "Game", null, null);
        if (self.window == null) {
            GL.glfwTerminate();
            std.debug.print("Failed to create window\n", .{});
            std.process.exit(1);
        }
        GL.glfwMakeContextCurrent(self.window);

        _ = GL.glfwSetMouseButtonCallback(self.window, mouse_button_callback);
        _ = GL.glfwSetKeyCallback(self.window, key_callback);
    }

    fn getMouseDX(self: *RubyDung) f32 {
        var xpos: f64 = 0;
        var ypos: f64 = 0;
        GL.glfwGetCursorPos(self.window, &xpos, &ypos);

        const mouseDX: f32 = @floatCast(xpos - self.lastMouseX);
        self.lastMouseX = xpos;
        return mouseDX;
    }

    fn getMouseDY(self: *RubyDung) f32 {
        var xpos: f64 = 0;
        var ypos: f64 = 0;
        GL.glfwGetCursorPos(self.window, &xpos, &ypos);

        ypos = -ypos;
        const mouseDY: f32 = @floatCast(ypos - self.lastMouseY);
        self.lastMouseY = ypos;
        return mouseDY;
    }

    // ----

    fn init() !*RubyDung {
        const self: *RubyDung = try allocator.create(RubyDung);

        const col: i32 = 0x0E0B0A;
        const fr: f32 = 0.5;
        const fg: f32 = 0.8;
        const fb: f32 = 1.0;
        self.fogColor[0] = @as(f32, (col >> 16) & 0xFF) / 255.0;
        self.fogColor[1] = @as(f32, (col >> 8 ) & 0xFF) / 255.0;
        self.fogColor[2] = @as(f32, (col >> 0 ) & 0xFF) / 255.0;
        self.fogColor[3] = 1.0;

        self.width = 1024;
        self.height = 768;
        self.setDisplayMode(self.width, self.height);
        self.cursor = GL.glfwCreateStandardCursor(GL.GLFW_ARROW_CURSOR);
        GL.glfwSetCursor(self.window, self.cursor);

        GL.glEnable(GL.GL_TEXTURE_2D);
        GL.glShadeModel(GL.GL_SMOOTH);
        GL.glClearColor(fr, fg, fb, 0.0);
        GL.glClearDepth(1.0);
        GL.glEnable(GL.GL_DEPTH_TEST);
        GL.glDepthFunc(GL.GL_LEQUAL);
        GL.glMatrixMode(GL.GL_PROJECTION);
        GL.glLoadIdentity();
        GL.glMatrixMode(GL.GL_MODELVIEW);

        self.level = try Level.new(256, 256, 64);
        self.levelRenderer = try LevelRenderer.new(self.level);
        self.player = try Player.init(self.level, self.window);
        self.timer = try Timer.new(60.0);

        GL.glfwSetInputMode(self.window, GL.GLFW_CURSOR, GL.GLFW_CURSOR_DISABLED);

        return self;
    }

    fn destroy(self: *RubyDung) !void {
        try self.level.save();

        GL.glfwDestroyCursor(self.cursor);
        GL.glfwDestroyWindow(self.window);
        GL.glfwTerminate();
    }

    fn run(self: *RubyDung) !void {
        var lastTime: i64 = std.time.milliTimestamp();
        var frames: i32 = 0;
        while (GL.glfwWindowShouldClose(self.window) == 0) {
            self.timer.advanceTime();
            for (0..@intCast(self.timer.ticks)) |i| {
                self.tick(); _ = i;
            }
            try self.render(self.timer.a);
            frames += 1;

            while (std.time.milliTimestamp() >= lastTime + 1000) {
                std.debug.print("{d} fps, {d}", .{ frames, Chunk.updates });
                Chunk.updates = 0;
                lastTime += 1000;
                frames = 0;
            }
        }

        try self.destroy();
    }

    fn tick(self: *RubyDung) void {
        self.player.tick();
    }

    fn moveCameraToPlayer(self: *RubyDung, a: f32) void {
        GL.glTranslatef(0.0, 0.0, -0.3);
        GL.glRotatef(self.player.xRot, 1.0, 0.0, 0.0);
        GL.glRotatef(self.player.yRot, 0.0, 1.0, 0.0);

        const x: f32 = self.player.xo + (self.player.x - self.player.xo) * a;
        const y: f32 = self.player.yo + (self.player.y - self.player.yo) * a;
        const z: f32 = self.player.zo + (self.player.z - self.player.zo) * a;
        GL.glTranslatef(-x, -y, -z);
    }

    fn setupCamera(self: *RubyDung, a: f32) void {
        GL.glMatrixMode(GL.GL_PROJECTION);
        GL.glLoadIdentity();
        GLU.gluPerspective(70.0, @floatFromInt(@divFloor(self.width, self.height)), 0.05, 1000.0);
        GL.glMatrixMode(GL.GL_MODELVIEW);
        GL.glLoadIdentity();
        self.moveCameraToPlayer(a);
    }

    fn setupPickCamera(self: *RubyDung, a: f32, x: i32, y: i32) void {
        GL.glMatrixMode(GL.GL_PROJECTION);
        GL.glLoadIdentity();
        self.viewportBuffer = [_]i32{0} ** 16;
        GL.glGetIntegerv(GL.GL_VIEWPORT, &self.viewportBuffer);
        GLU.gluPickMatrix(@floatFromInt(x), @floatFromInt(y), 5.0, 5.0, &self.viewportBuffer);
        GLU.gluPerspective(70.0, @floatFromInt(@divFloor(self.width, self.height)), 0.05, 1000.0);
        GL.glMatrixMode(GL.GL_MODELVIEW);
        GL.glLoadIdentity();
        self.moveCameraToPlayer(a);
    }

    fn pick(self: *RubyDung, a: f32) !void {
        self.selectBuffer = [_]u32{0} ** 2000;
        GL.glSelectBuffer(2000, &self.selectBuffer);
        _ = GL.glRenderMode(GL.GL_SELECT);
        self.setupPickCamera(a, @divFloor(self.width, 2), @divFloor(self.height, 2));
        self.levelRenderer.pick(self.player);

        const hits: i32 = GL.glRenderMode(GL.GL_RENDER);
        var closest: i64 = 0;
        var names: [10]i32 = [_]i32{0} ** 10;
        var hitNameCount: i32 = 0;
        var index: i32 = 0;

        for (0..@intCast(hits)) |i| {
            const nameCount: u32 = self.selectBuffer[@intCast(index)];
            index += 1;
            const minZ: i64 = self.selectBuffer[@intCast(index)];
            index += 2;

            const dist: i64 = minZ;
            if (dist < closest or i == 0) {
                closest = dist;
                hitNameCount = @intCast(nameCount);
                for (&names) |*j| {
                    j.* = @intCast(self.selectBuffer[@intCast(index)]);
                    index += 1;
                }
            } else {
                index += @intCast(nameCount);
            }
        }

        if (self.hitResult != null) {
            std.debug.print("OLD hitresult: {*}\n", .{self.hitResult});
            const res: *HitResult = self.hitResult.?;
            allocator.destroy(res);
            self.hitResult = null;
        }
        if (hitNameCount > 0) {
            self.hitResult = try HitResult.new(names[0], names[1], names[2], names[3], names[4]);
            std.debug.print("NEW hitresult: {*}\n", .{self.hitResult});
        }
    }

    fn render(self: *RubyDung, a: f32) !void {
        const xo: f32 = self.getMouseDX();
        const yo: f32 = self.getMouseDY();
        self.player.turn(xo, yo);
        try self.pick(a);

        GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
        self.setupCamera(a);
        GL.glEnable(GL.GL_CULL_FACE);
        GL.glEnable(GL.GL_FOG);
        GL.glFogi(GL.GL_FOG_MODE, 2048);
        GL.glFogf(GL.GL_FOG_DENSITY, 0.2);
        GL.glFogfv(GL.GL_FOG_COLOR, &self.fogColor);
        GL.glDisable(GL.GL_FOG);
        self.levelRenderer.render(self.player, 0);
        GL.glEnable(GL.GL_FOG);
        self.levelRenderer.render(self.player, 1);
        GL.glDisable(GL.GL_TEXTURE_2D);
        if (self.hitResult != null) {
            self.levelRenderer.renderHit(self.hitResult.?);
        }
        GL.glDisable(GL.GL_FOG);
        GL.glfwSwapBuffers(self.window);
        GL.glfwPollEvents();
    }
};

var rd: *RubyDung = undefined;

fn initExternal() !void {
    Frustum.frustum = try Frustum.new();
}

pub fn main() !void {
    try initExternal();

    rd = try RubyDung.init();

    try rd.run();
}

fn mouse_button_callback(window: ?*GL.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    rd.mouseButtonCallback(window.?, @as(i32, button), @as(i32, action), @as(i32, mods));
}

fn key_callback(window: ?*GL.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    rd.keyCallback(window.?, @as(i32, key), @as(i32, scancode), @as(i32, action), @as(i32, mods));
}
