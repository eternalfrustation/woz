/// This follows the stable spec as of 08 May 2024
/// at https://devicetree-specification.readthedocs.io/en/stable/flattened-format.html
const std = @import("std");
const builtin = @import("builtin");
const debug = @import("../opensbi/debug.zig");
pub const Header = packed struct {
    magic: u32,
    total_size: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rsvmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_struct: u32,
};

/// For filling a struct from big endian data
/// The struct MUST have the entries with the same data type
pub fn GenericFromAddress(comptime T: type, comptime IntType: type, a: usize) T {
    var t: T = undefined;
    if (builtin.cpu.arch.endian() == std.builtin.Endian.big) {
        const store_bytes: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType align(@alignOf(IntType)) = @ptrCast(&t);
        const buf: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType = @ptrFromInt(a);
        std.mem.copyForwards(IntType, store_bytes, buf);
    } else {
        var store_bytes: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType align(@alignOf(IntType)) = @ptrCast(&t);
        const buf: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType = @ptrFromInt(a);
        for (0..store_bytes.len, buf) |i, *b| {
            store_bytes[i] = std.mem.readInt(IntType, std.mem.asBytes(b), std.builtin.Endian.big);
        }
    }
    return t;
}

pub const FdtReserveEntry = packed struct {
    address: u64,
    size: u64,
};

pub const FdtTokenError = error{
    UNKNOWN_TOKEN_TYPE,
};

pub const RawFdtToken = union(enum) {
    FDT_NOOP: void,
    FDT_BEGIN: packed struct { name: [*:0]const u8 },
    FDT_PROP: struct { nameoff: u32, value: []u8 },
    FDT_END: void,
    FDT_END_NODE: void,
    pub fn FromAddress(a: usize) !RawFdtToken {
        const token_identifier: u32 = GenericFromAddress(u32, u32, a);
        var printBuffer: [256]u8 = undefined;
        const out = std.fmt.bufPrint(&printBuffer, "\ntoken identifier: {}\n", .{token_identifier}) catch unreachable;
        _ = debug.print(out) catch 0;

        switch (token_identifier) {
            0x00000001 => {
                return RawFdtToken{ .FDT_BEGIN = .{ .name = @ptrFromInt(a + 4) } };
            },
            0x00000002 => {
                return RawFdtToken.FDT_END_NODE;
            },
            0x00000003 => {
                var t: struct { nameoff: u32, value: []u8 } = undefined;
                if (builtin.cpu.arch.endian() == std.builtin.Endian.big) {
                    t.value.len = @as(*u32, @ptrFromInt(a + 4)).*;
                    t.nameoff = @as(*u32, @ptrFromInt(a + 8)).*;
                    t.value.ptr = @ptrFromInt(a + 12);
                } else {
                    t.value.len = std.mem.readInt(u32, @as(*[4]u8, @ptrFromInt(a + 4)), std.builtin.Endian.big);
                    t.nameoff = std.mem.readInt(u32, @as(*[4]u8, @ptrFromInt(a + 8)), std.builtin.Endian.big);
                    t.value.ptr = @ptrFromInt(a + 12);
                }
                return RawFdtToken{ .FDT_PROP = .{ .nameoff = t.nameoff, .value = t.value } };
            },
            0x00000004 => {
                return RawFdtToken.FDT_NOOP;
            },
            0x00000009 => {
                return RawFdtToken.FDT_END;
            },
            else => {
                return FdtTokenError.UNKNOWN_TOKEN_TYPE;
            },
        }
    }
};

pub const FdtProp = packed struct {
    len: u32,
    nameoff: u32,
    value: [*:0]const u8,
};
