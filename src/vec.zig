pub const FVec = struct {
    x: f64,
    y: f64,

    pub fn from_ivec(ivec: IVec) FVec {
        return FVec{ .x = @floatFromInt(ivec.x), .y = @floatFromInt(ivec.y) };
    }

    pub fn plus(self: FVec, other: FVec) FVec {
        return FVec{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn times(self: FVec, scaler: f64) FVec {
        return FVec{
            .x = self.x * scaler,
            .y = self.y * scaler,
        };
    }

    pub fn plus_val(self: FVec, val: f64) FVec {
        return FVec{
            .x = self.x + val,
            .y = self.y + val,
        };
    }
};

pub const IVec = struct { x: c_int, y: c_int };
