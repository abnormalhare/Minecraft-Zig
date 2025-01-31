const GL = @import("glfw3");

const MAX_VERTICES: i32 = 100000;

pub const Tesselator = struct {
    vertexBuffer: [3 * MAX_VERTICES]f32,
    texCoordBuffer: [2 * MAX_VERTICES]f32,
    colorBuffer: [3 * MAX_VERTICES]f32,

    vertices: i32 = 0,
    u: f32, v: f32,
    r: f32, g: f32, b: f32,
    
    hasColor: bool = false,
    hasTexture: bool = false,

    pub fn flush(self: *Tesselator) void {
        GL.glVertexPointer(3, GL.GL_FLOAT, 0, &self.vertexBuffer);
        if (self.hasTexture)
            GL.glTexCoordPointer(2, GL.GL_FLOAT, 0, &self.texCoordBuffer);
        if (self.hasColor)
            GL.glColorPointer(3, GL.GL_FLOAT, 0, &self.colorBuffer);

        GL.glEnableClientState(GL.GL_VERTEX_ARRAY);
        if (self.hasTexture)
            GL.glEnableClientState(GL.GL_TEXTURE_COORD_ARRAY);
        if (self.hasColor)
            GL.glEnableClientState(GL.GL_COLOR_ARRAY);
        
        GL.glDrawArrays(GL.GL_QUADS, 0, self.vertices);

        GL.glDisableClientState(GL.GL_VERTEX_ARRAY);
        if (self.hasTexture)
            GL.glDisableClientState(GL.GL_TEXTURE_COORD_ARRAY);
        if (self.hasColor)
            GL.glDisableClientState(GL.GL_COLOR_ARRAY);
        
        self.clear();
    }

    fn clear(self: *Tesselator) void {
        self.vertices = 0;
        self.vertexBuffer = [_]f32{0} ** (3 * MAX_VERTICES);
        self.texCoordBuffer = [_]f32{0} ** (2 * MAX_VERTICES);
        self.colorBuffer = [_]f32{0} ** (3 * MAX_VERTICES);
    }

    pub fn init(self: *Tesselator) void {
        self.clear();
        self.hasColor = false;
        self.hasTexture = false;
    }

    pub fn tex(self: *Tesselator, u: f32, v: f32) void {
        self.hasTexture = true;
        self.u = u;
        self.v = v;
    }

    pub fn color(self: *Tesselator, r: f32, g: f32, b: f32) void {
        self.hasColor = true;
        self.r = r;
        self.g = g;
        self.b = b;
    }

    pub fn vertex(self: *Tesselator, x: f32, y: f32, z: f32) void {
        self.vertexBuffer[@intCast(self.vertices * 3 + 0)] = x;
        self.vertexBuffer[@intCast(self.vertices * 3 + 1)] = y;
        self.vertexBuffer[@intCast(self.vertices * 3 + 2)] = z;

        if (self.hasTexture) {
            self.vertexBuffer[@intCast(self.vertices * 2 + 0)] = self.u;
            self.vertexBuffer[@intCast(self.vertices * 2 + 1)] = self.v;
        }

        if (self.hasColor) {
            self.vertexBuffer[@intCast(self.vertices * 3 + 0)] = self.r;
            self.vertexBuffer[@intCast(self.vertices * 3 + 1)] = self.g;
            self.vertexBuffer[@intCast(self.vertices * 3 + 2)] = self.b;
        }

        self.vertices += 1;
        if (self.vertices == MAX_VERTICES) {
            self.flush();
        }
    }
};