const SERIAL_ADDR: *[8]u8 = @ptrFromInt(0x10000000);

pub fn kprint_uart(str: []const u8, len: usize) void {
    for (0..len) |i| {
        kputc_uart(str[i]);
    }
}

pub fn kputc_uart(c: u8) void {
    SERIAL_ADDR.*[0] = c;
}

pub fn kreadc_uart() ?u8 {
    if (0x1 & SERIAL_ADDR.*[5] == 1) {
        return SERIAL_ADDR.*[0];
    } else {
        return null;
    }
}
