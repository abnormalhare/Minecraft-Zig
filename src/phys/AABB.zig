const std = @import("std");

pub const AABB = struct {
    x0: f32, y0: f32, z0: f32,
    x1: f32, y1: f32, z1: f32,
    
    epsilon: f32 = 1.0,

    pub fn expand(self: *AABB, xa: f32, ya: f32, za: f32) AABB {
        var _x0: f32 = self.x0;
        var _y0: f32 = self.y0;
        var _z0: f32 = self.z0;
        var _x1: f32 = self.x1;
        var _y1: f32 = self.y1;
        var _z1: f32 = self.z1;

        if (xa < 0.0) _x0 += xa;
        if (xa > 0.0) _x1 += xa;
        if (ya < 0.0) _y0 += ya;
        if (ya > 0.0) _y1 += ya;
        if (za < 0.0) _z0 += za;
        if (za > 0.0) _z1 += za;

        return AABB{
            .x0 = _x0, .y0 = _y0, .z0 = _z0,
            .x1 = _x1, .y1 = _y1, .z1 = _z1
        };
    }

    pub fn grow(self: *AABB, xa: f32, ya: f32, za: f32) AABB {
        const _x0: f32 = self.x0 - xa;
        const _y0: f32 = self.y0 - ya;
        const _z0: f32 = self.z0 - za;
        const _x1: f32 = self.x1 + xa;
        const _y1: f32 = self.y1 + ya;
        const _z1: f32 = self.z1 + za;

        return AABB{
            .x0 = _x0, .y0 = _y0, .z0 = _z0,
            .x1 = _x1, .y1 = _y1, .z1 = _z1
        };
    }

    pub fn clipXCollide(self: *AABB, c: AABB, xa: f32) f32 {
        if (c.y1 <= self.y0 or c.y0 >= self.y1) return xa;
        if (c.z1 <= self.z0 or c.z0 >= self.z1) return xa;

        var _xa: f32 = xa;

        if (_xa > 0.0 and c.x1 <= self.x0) {
            const max: f32 = self.x0 - c.x1 - self.epsilon;
            if (max < _xa) _xa = max;
        }

        if (_xa < 0.0 and c.x0 >= self.x1) {
            const max: f32 = self.x1 - c.x0 + self.epsilon;
            if (max > _xa) _xa = max;
        }

        return _xa;
    }

    pub fn clipYCollide(self: *AABB, c: AABB, ya: f32) f32 {
        if (c.x1 <= self.x0 or c.x0 >= self.x1) return ya;
        if (c.z1 <= self.z0 or c.z0 >= self.z1) return ya;

        var _ya: f32 = ya;

        if (_ya > 0.0 and c.y1 <= self.y0) {
            const max: f32 = self.y0 - c.y1 - self.epsilon;
            if (max < _ya) _ya = max;
        }

        if (_ya < 0.0 and c.y0 >= self.y1) {
            const max: f32 = self.y1 - c.y0 + self.epsilon;
            if (max > _ya) _ya = max;
        }

        return _ya;
    }

    pub fn clipZCollide(self: *AABB, c: AABB, za: f32) f32 {
        if (c.x1 <= self.x0 or c.x0 >= self.x1) return za;
        if (c.y1 <= self.y0 or c.y0 >= self.y1) return za;

        var _za: f32 = za;

        if (_za > 0.0 and c.z1 <= self.z0) {
            const max: f32 = self.z0 - c.z1 - self.epsilon;
            if (max < _za) _za = max;
        }

        if (_za < 0.0 and c.z0 >= self.z1) {
            const max: f32 = self.z1 - c.z0 + self.epsilon;
            if (max > _za) _za = max;
        }

        return _za;
    }

    pub fn intersects(self: *AABB, c: AABB) bool {
        if (c.x1 <= self.x0 or c.x0 >= self.x1) return false;
        if (c.y1 <= self.y0 or c.y0 >= self.y1) return false;
        if (c.z1 <= self.z0 or c.z0 >= self.z1) return false;

        return true;
    }

    pub fn move(self: *AABB, xa: f32, ya: f32, za: f32) void {
        self.x0 += xa; self.y0 += ya; self.z0 += za;
        self.x1 += xa; self.y1 += ya; self.z1 += za;
    }
};