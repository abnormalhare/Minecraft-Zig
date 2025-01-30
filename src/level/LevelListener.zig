pub const LevelListener = struct {
    tileChanged:        *fn(self: *LevelListener, paramInt1: i32, paramInt2: i32, paramInt3: i32) void,
    lightColumnChanged: *fn(self: *LevelListener, paramInt1: i32, paramInt2: i32, paramInt3: i32, paramInt4: i32) void,
    allChanged:         *fn(self: *LevelListener) void,
    base: *anyopaque,
};