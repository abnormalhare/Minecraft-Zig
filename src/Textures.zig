const std = @import("std");
const GL = @import("glfw3");
const zstbi = @import("zstbi");
const GLU = @cImport({
    @cInclude("C:/msys64/ucrt64/include/GL/glu.h");
});

pub const Textures = struct {
    const idMap = std.AutoHashMap([]const u8, i32).init(std.heap.page_allocator);

    const lastId: i32 = -9999999;

    fn loadTexture(resourceName: []const u8, mode: i32) i32 {
        if (idMap.contains(resourceName)) {
            return idMap.get(resourceName);
        }

        const id: i32 = 0;
        GL.glGenTextures(1, &id);
        bind(id);
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, mode);
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, mode);

        const img: zstbi.Image = zstbi.Image.loadFromFile("../terrain.png", 4);
        defer img.deinit();
        const w: i32 = img.width;
        const h: i32 = img.height;
        GLU.gluBuild2DMipmaps(GL.GL_TEXTURE_2D, GL.GL_RGBA, w, h, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, img);

        return id;
    }

    fn bind(id: i32) void {
        if (id != lastId) {
            GL.bindTexture(GL.GL_TEXTURE_2D, id);
            lastId = id;
        }
    }
};
