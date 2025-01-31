const std = @import("std");
const allocator = @import("root.zig").allocator;
const GL = @import("glfw3");
const zstbi = @import("zstbi");
const GLU = @cImport({
    @cInclude("C:/msys64/ucrt64/include/GL/glu.h");
});

pub const Textures = struct {
    const idMap = std.StringHashMap(i32).init(allocator);

    var lastId: i32 = -9999999;

    pub fn loadTexture(resourceName: []const u8, mode: i32) i32 {
        if (idMap.contains(resourceName)) {
            return idMap.get(resourceName).?;
        }

        var id: i32 = 0;
        GL.glGenTextures(1, @ptrCast(&id));
        bind(id);
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, mode);
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, mode);

        zstbi.init(allocator);
        defer zstbi.deinit();

        var img: zstbi.Image = zstbi.Image.loadFromFile("./terrain.png", 4)
        catch |err| switch (err) {
            error.ImageInitFailed => {
                std.debug.print("Image Failed to Load\n", .{});
                std.process.exit(1);
            }
        };
        const w: c_int = @intCast(img.width);
        const h: c_int = @intCast(img.height);
        const data: *u8 = &img.data[0];
        _ = GLU.gluBuild2DMipmaps(GL.GL_TEXTURE_2D, GL.GL_RGBA, w, h, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, data);

        img.deinit();

        return id;
    }

    fn bind(id: i32) void {
        if (id != lastId) {
            GL.glBindTexture(GL.GL_TEXTURE_2D, @intCast(id));
            lastId = id;
        }
    }
};
