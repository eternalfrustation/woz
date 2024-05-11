const bufPrint = @import("std").fmt.bufPrint;
const bufPrintError = @import("std").fmt.BufPrintError;
const std = @import("std");
const common = @import("../opensbi.zig");
// a7 has the extension id
// a6 has the function id
// a0, a1, a2... have the arguments to the function
// ecall to finally call the function
// a0 has the return code
// a1 has the return value

pub fn printHex(comptime T: type, x: T) !usize {
    const bytes = std.mem.asBytes(&x);
    for (0..bytes.len, bytes) |i, b| {
        const lowerBytes: u4 = @truncate(b & 0b00001111);
        const upperBytes: u4 = @truncate((b & 0b11110000) >> 4);
        _ = try write_char(toHex(upperBytes));
        _ = try write_char(toHex(lowerBytes));
        if (i % 4 != 3) {
            _ = try write_char(' ');
        } else if (i % 8 != 7) {
            _ = try write_char('\t');
        } else {
            _ = try write_char('\n');
        }
    }
    return bytes.len * 3 - 1;
}

pub fn toHex(x: u4) u8 {
    if (x > 9) {
        return 'A' + @as(u8, x - 10);
    } else {
        return '0' + @as(u8, x);
    }
}

pub fn print(s: []const u8) !usize {
    const err_code = asm (
        \\ li a7, 0x4442434E
        \\ li a6, 0x0
        \\ li a2, 0
        \\ ecall
        : [err] "={a0}" (-> isize),
        : [len] "{a0}" (s.len),
          [ptr] "{a1}" (s.ptr),
    );
    // temporary fix till zig supports multiple return values from assembly
    const bytes_written = asm (
        \\
        : [val] "={a1}" (-> usize),
    );
    return switch (err_code) {
        0 => bytes_written,
        -9...-1 => common.err_from_int(err_code),
        else => unreachable,
    };
}

pub fn read_str(arr: []const u8) !usize {
    const err_code = asm (
        \\ li a7, 0x4442434E
        \\ li a6, 0x1
        \\ li a2, 0
        \\ ecall
        : [err] "={a0}" (-> isize),
        : [len] "{a0}" (arr.len),
          [ptr] "{a1}" (arr.ptr),
    );
    // temporary fix till zig supports multiple return values from assembly
    const value = asm (
        \\
        : [val] "={a1}" (-> usize),
    );
    return switch (err_code) {
        0 => value,
        -9...-1 => common.err_from_int(err_code),
        else => unreachable,
    };
}

pub fn read_char(a: *u8) !usize {
    const err_code = asm (
        \\ li a7, 0x4442434E
        \\ li a6, 0x1
        \\ li a2, 0
        \\ ecall
        : [err] "={a0}" (-> isize),
        : [len] "{a0}" (1),
          [ptr] "{a1}" (a),
    );
    // temporary fix till zig supports multiple return values from assembly
    const value = asm (
        \\
        : [val] "={a1}" (-> usize),
    );
    return switch (err_code) {
        0 => value,
        -9...-1 => common.err_from_int(err_code),
        else => unreachable,
    };
}

pub fn write_char(c: u8) !usize {
    const err_code = asm (
        \\ li a7, 0x4442434E
        \\ li a6, 0x2
        \\ li a2, 0
        \\ ecall
        : [err] "={a0}" (-> isize),
        : [len] "{a0}" (c),
    );
    // temporary fix till zig supports multiple return values from assembly
    const bytes_written = asm (
        \\
        : [val] "={a1}" (-> usize),
    );
    return switch (err_code) {
        0 => bytes_written,
        -9...-1 => common.err_from_int(err_code),
        else => unreachable,
    };
}
