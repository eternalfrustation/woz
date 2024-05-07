const std = @import("std");
const common = @import("../opensbi.zig");
// a7 has the extension id
// a6 has the function id
// a0, a1, a2... have the arguments to the function
// ecall to finally call the function
// a0 has the return code
// a1 has the return value
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
