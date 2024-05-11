pub const PageBits = enum(u2) {
    Empty,
    Taken,
    Last,
    fn is_free(self: PageBits) bool {
        return self & 0b01 == 0;
    }
    fn is_last(self: PageBits) bool {
        return self & 0b10 != 0;
    }
};
