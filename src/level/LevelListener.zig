pub const LevelListener = struct {
    tileChanged:        *const fn(self: *LevelListener, paramInt1: i32, paramInt2: i32, paramInt3: i32) void,
    lightColumnChanged: *const fn(self: *LevelListener, paramInt1: i32, paramInt2: i32, paramInt3: i32, paramInt4: i32) void,
    allChanged:         *const fn(self: *LevelListener) void,
    base: *anyopaque,
};