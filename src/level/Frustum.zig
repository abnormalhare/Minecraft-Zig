const std = @import("std");
const allocator = @import("../root.zig").allocator;
const GL = @import("glfw3");

const AABB = @import("../phys/AABB.zig").AABB;

pub const Frustum = struct {
    m_Frustum: [6][4]f32,
    proj: [16]f32,
    modl: [16]f32,
    clip: [16]f32,

    pub var frustum: *Frustum = undefined;

    pub fn new() !*Frustum {
        const f: *Frustum = try allocator.create(Frustum);
        return f;
    }

    pub fn getFrustum() *Frustum {
        frustum.calculateFrustum();
        return frustum;
    }

    fn normalizePlane(_frustum: *[6][4]f32, side: i32) void {
        const sideu: usize = @intCast(side);
        const magnitude: f32 = std.math.sqrt(_frustum[sideu][0] * _frustum[sideu][0] +
            _frustum[sideu][1] * _frustum[sideu][1] +
            _frustum[sideu][2] * _frustum[sideu][2]);

        _frustum[sideu][0] /= magnitude;
        _frustum[sideu][1] /= magnitude;
        _frustum[sideu][2] /= magnitude;
        _frustum[sideu][3] /= magnitude;
    }

    fn calculateFrustum(self: *Frustum) void {
        self.proj = [_]f32{0} ** 16;
        self.modl = [_]f32{0} ** 16;
        self.clip = [_]f32{0} ** 16;

        GL.glGetFloatv(GL.GL_PROJECTION_MATRIX, &self.proj);
        GL.glGetFloatv(GL.GL_MODELVIEW_MATRIX, &self.modl);

        self.clip[0] = self.modl[0] * self.proj[0] + self.modl[1] * self.proj[4] + self.modl[2] * self.proj[8] + self.modl[3] * self.proj[12];
        self.clip[1] = self.modl[0] * self.proj[1] + self.modl[1] * self.proj[5] + self.modl[2] * self.proj[9] + self.modl[3] * self.proj[13];
        self.clip[2] = self.modl[0] * self.proj[2] + self.modl[1] * self.proj[6] + self.modl[2] * self.proj[10] + self.modl[3] * self.proj[14];
        self.clip[3] = self.modl[0] * self.proj[3] + self.modl[1] * self.proj[7] + self.modl[2] * self.proj[11] + self.modl[3] * self.proj[15];
        self.clip[4] = self.modl[4] * self.proj[0] + self.modl[5] * self.proj[4] + self.modl[6] * self.proj[8] + self.modl[7] * self.proj[12];
        self.clip[5] = self.modl[4] * self.proj[1] + self.modl[5] * self.proj[5] + self.modl[6] * self.proj[9] + self.modl[7] * self.proj[13];
        self.clip[6] = self.modl[4] * self.proj[2] + self.modl[5] * self.proj[6] + self.modl[6] * self.proj[10] + self.modl[7] * self.proj[14];
        self.clip[7] = self.modl[4] * self.proj[3] + self.modl[5] * self.proj[7] + self.modl[6] * self.proj[11] + self.modl[7] * self.proj[15];
        self.clip[8] = self.modl[8] * self.proj[0] + self.modl[9] * self.proj[4] + self.modl[10] * self.proj[8] + self.modl[11] * self.proj[12];
        self.clip[9] = self.modl[8] * self.proj[1] + self.modl[9] * self.proj[5] + self.modl[10] * self.proj[9] + self.modl[11] * self.proj[13];
        self.clip[10] = self.modl[8] * self.proj[2] + self.modl[9] * self.proj[6] + self.modl[10] * self.proj[10] + self.modl[11] * self.proj[14];
        self.clip[11] = self.modl[8] * self.proj[3] + self.modl[9] * self.proj[7] + self.modl[10] * self.proj[11] + self.modl[11] * self.proj[15];
        self.clip[12] = self.modl[12] * self.proj[0] + self.modl[13] * self.proj[4] + self.modl[14] * self.proj[8] + self.modl[15] * self.proj[12];
        self.clip[13] = self.modl[12] * self.proj[1] + self.modl[13] * self.proj[5] + self.modl[14] * self.proj[9] + self.modl[15] * self.proj[13];
        self.clip[14] = self.modl[12] * self.proj[2] + self.modl[13] * self.proj[6] + self.modl[14] * self.proj[10] + self.modl[15] * self.proj[14];
        self.clip[15] = self.modl[12] * self.proj[3] + self.modl[13] * self.proj[7] + self.modl[14] * self.proj[11] + self.modl[15] * self.proj[15];

        self.m_Frustum[0][0] = self.clip[3] - self.clip[0];
        self.m_Frustum[0][1] = self.clip[7] - self.clip[4];
        self.m_Frustum[0][2] = self.clip[11] - self.clip[8];
        self.m_Frustum[0][3] = self.clip[15] - self.clip[12];
        normalizePlane(&self.m_Frustum, 0);
        self.m_Frustum[1][0] = self.clip[3] + self.clip[0];
        self.m_Frustum[1][1] = self.clip[7] + self.clip[4];
        self.m_Frustum[1][2] = self.clip[11] + self.clip[8];
        self.m_Frustum[1][3] = self.clip[15] + self.clip[12];
        normalizePlane(&self.m_Frustum, 1);
        self.m_Frustum[2][0] = self.clip[3] + self.clip[1];
        self.m_Frustum[2][1] = self.clip[7] + self.clip[5];
        self.m_Frustum[2][2] = self.clip[11] + self.clip[9];
        self.m_Frustum[2][3] = self.clip[15] + self.clip[13];
        normalizePlane(&self.m_Frustum, 2);
        self.m_Frustum[3][0] = self.clip[3] - self.clip[1];
        self.m_Frustum[3][1] = self.clip[7] - self.clip[5];
        self.m_Frustum[3][2] = self.clip[11] - self.clip[9];
        self.m_Frustum[3][3] = self.clip[15] - self.clip[13];
        normalizePlane(&self.m_Frustum, 3);
        self.m_Frustum[4][0] = self.clip[3] - self.clip[2];
        self.m_Frustum[4][1] = self.clip[7] - self.clip[6];
        self.m_Frustum[4][2] = self.clip[11] - self.clip[10];
        self.m_Frustum[4][3] = self.clip[15] - self.clip[14];
        normalizePlane(&self.m_Frustum, 4);
        self.m_Frustum[5][0] = self.clip[3] + self.clip[2];
        self.m_Frustum[5][1] = self.clip[7] + self.clip[6];
        self.m_Frustum[5][2] = self.clip[11] + self.clip[10];
        self.m_Frustum[5][3] = self.clip[15] + self.clip[14];
        normalizePlane(&self.m_Frustum, 5);
    }

    pub fn pointInFrustum(self: *Frustum, x: f32, y: f32, z: f32) bool {
        inline for (0..6) |i| {
            if (self.m_Frustum[i][0] * x + self.m_Frustum[i][1] * y + self.m_Frustum[i][2] * z + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
        }
        return true;
    }

    pub fn sphereInFrustum(self: *Frustum, x: f32, y: f32, z: f32, radius: f32) bool {
        inline for (0..6) |i| {
            if (self.m_Frustum[i][0] * x + self.m_Frustum[i][1] * y + self.m_Frustum[i][2] * z + self.m_Frustum[i][3] <= -radius) {
                return false;
            }
        }
        return true;
    }

    pub fn cubeFullyInFrustum(self: *Frustum, x1: f32, y1: f32, z1: f32, x2: f32, y2: f32, z2: f32) bool {
        for (0..6) |i| {
            if (self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] <= 0.0) {
                return false;
            }
        }
        return true;
    }

    pub fn cubeInFrustum(self: *Frustum, x1: f32, y1: f32, z1: f32, x2: f32, y2: f32, z2: f32) bool {
        for (0..6) |i| {
            if (self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z1 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y1 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x1 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] > 0.0 or
                self.m_Frustum[i][0] * x2 + self.m_Frustum[i][1] * y2 + self.m_Frustum[i][2] * z2 + self.m_Frustum[i][3] > 0.0) {
                continue;
            }
            return false;
        }
        return true;
    }

    pub fn cubeInFrustumA(self: *Frustum, aabb: AABB) bool {
        return self.cubeInFrustum(aabb.x0, aabb.y0, aabb.z0, aabb.x1, aabb.y1, aabb.z1);
    }
};
