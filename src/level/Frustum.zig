const std = @import("std");
const GL = @import("glfw3");

const AABB = @import("../phys/AABB.zig").AABB;

const FDir = enum(i32) { RIGHT, LEFT, BOTTOM, TOP, BACK, FRONT };

const FCor = enum(i32) { A, B, C, D };

const frustum: Frustum = Frustum.new();

pub const Frustum = struct {
    m_Frustum: [6][4]f32,
    proj: [16]f32,
    modl: [16]f32,
    clip: [16]f32,

    fn getFrustum() Frustum {
        frustum.calculateFrustum();
        return frustum;
    }

    fn normalizePlane(_frustum: [][]f32, side: i32) void {
        const magnitude: f32 = std.math.sqrt(_frustum[side][0] * _frustum[side][0] +
            _frustum[side][1] * _frustum[side][1] +
            _frustum[side][2] * _frustum[side][2]);

        frustum[side][FCor.A] /= magnitude;
        frustum[side][FCor.B] /= magnitude;
        frustum[side][FCor.C] /= magnitude;
        frustum[side][FCor.D] /= magnitude;
    }

    fn calculateFrustum(self: *Frustum) void {
        self.proj = [_]f32{0} ** 16;
        self.modl = [_]f32{0} ** 16;
        self.clip = [_]f32{0} ** 16;

        GL.glGetFloatv(GL.GL_PROJECTION_MATRIX, self.proj);
        GL.glGetFloatv(GL.GL_MODELVIEW_MATRIX, self.modl);

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

        self.m_Frustum[FDir.RIGHT][FCor.A] = self.clip[3] - self.clip[0];
        self.m_Frustum[FDir.RIGHT][FCor.B] = self.clip[7] - self.clip[4];
        self.m_Frustum[FDir.RIGHT][FCor.C] = self.clip[11] - self.clip[8];
        self.m_Frustum[FDir.RIGHT][FCor.D] = self.clip[15] - self.clip[12];
        normalizePlane(self.m_Frustum, 0);
        self.m_Frustum[FDir.LEFT][FCor.A] = self.clip[3] + self.clip[0];
        self.m_Frustum[FDir.LEFT][FCor.B] = self.clip[7] + self.clip[4];
        self.m_Frustum[FDir.LEFT][FCor.C] = self.clip[11] + self.clip[8];
        self.m_Frustum[FDir.LEFT][FCor.D] = self.clip[15] + self.clip[12];
        normalizePlane(self.m_Frustum, 1);
        self.m_Frustum[FDir.BOTTOM][FCor.A] = self.clip[3] + self.clip[1];
        self.m_Frustum[FDir.BOTTOM][FCor.B] = self.clip[7] + self.clip[5];
        self.m_Frustum[FDir.BOTTOM][FCor.C] = self.clip[11] + self.clip[9];
        self.m_Frustum[FDir.BOTTOM][FCor.D] = self.clip[15] + self.clip[13];
        normalizePlane(self.m_Frustum, 2);
        self.m_Frustum[FDir.TOP][FCor.A] = self.clip[3] - self.clip[1];
        self.m_Frustum[FDir.TOP][FCor.B] = self.clip[7] - self.clip[5];
        self.m_Frustum[FDir.TOP][FCor.C] = self.clip[11] - self.clip[9];
        self.m_Frustum[FDir.TOP][FCor.D] = self.clip[15] - self.clip[13];
        normalizePlane(self.m_Frustum, 3);
        self.m_Frustum[FDir.BACK][FCor.A] = self.clip[3] - self.clip[2];
        self.m_Frustum[FDir.BACK][FCor.B] = self.clip[7] - self.clip[6];
        self.m_Frustum[FDir.BACK][FCor.C] = self.clip[11] - self.clip[10];
        self.m_Frustum[FDir.BACK][FCor.D] = self.clip[15] - self.clip[14];
        normalizePlane(self.m_Frustum, 4);
        self.m_Frustum[FDir.FRONT][FCor.A] = self.clip[3] + self.clip[2];
        self.m_Frustum[FDir.FRONT][FCor.B] = self.clip[7] + self.clip[6];
        self.m_Frustum[FDir.FRONT][FCor.C] = self.clip[11] + self.clip[10];
        self.m_Frustum[FDir.FRONT][FCor.D] = self.clip[15] + self.clip[14];
        normalizePlane(self.m_Frustum, 5);
    }

    fn pointInFrustum(self: *Frustum, x: f32, y: f32, z: f32) bool {
        inline for (std.meta.fields(FDir)) |i| {
            if (self.m_Frustum[i][FCor.A] * x + self.m_Frustum[i][FCor.B] * y + self.m_Frustum[i][FCor.C] * z + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
        }
        return true;
    }

    fn sphereInFrustum(self: *Frustum, x: f32, y: f32, z: f32, radius: f32) bool {
        inline for (std.meta.fields(FDir)) |i| {
            if (self.m_Frustum[i][FCor.A] * x + self.m_Frustum[i][FCor.B] * y + self.m_Frustum[i][FCor.C] * z + self.m_Frustum[i][FCor.D] <= -radius) {
                return false;
            }
        }
        return true;
    }

    fn cubeFullyInFrustum(self: *Frustum, x1: f32, y1: f32, z1: f32, x2: f32, y2: f32, z2: f32) bool {
        inline for (std.meta.fields(FDir)) |i| {
            if (self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
            if (self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
        }
        return true;
    }

    fn cubeInFrustum(self: *Frustum, x1: f32, y1: f32, z1: f32, x2: f32, y2: f32, z2: f32) bool {
        inline for (std.meta.fields(FDir)) |i| {
            if (self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z1 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y1 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x1 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0 or self.m_Frustum[i][FCor.A] * x2 + self.m_Frustum[i][FCor.B] * y2 + self.m_Frustum[i][FCor.C] * z2 + self.m_Frustum[i][FCor.D] <= 0.0) {
                return false;
            }
        }
        return true;
    }

    fn cubeInFrustumA(self: *Frustum, aabb: AABB) bool {
        return self.cubeInFrustum(aabb.x0, aabb.y0, aabb.z0, aabb.x1, aabb.y1, aabb.z1);
    }
};
