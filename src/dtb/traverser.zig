/// This follows the stable spec as of 08 May 2024
/// at https://devicetree-specification.readthedocs.io/en/stable/flattened-format.html
const std = @import("std");
const builtin = @import("builtin");
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
/// No allocations are internaly performed, so make sure store has been already allocated
pub fn FromAddress(comptime T: type, comptime IntType: type, store: *T, a: usize) void {
    if (builtin.cpu.arch.endian() == std.builtin.Endian.big) {
        const store_bytes: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType align(32) = @ptrCast(store);
        const buf: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType = @ptrFromInt(a);
        std.mem.copyForwards(IntType, store_bytes, buf);
    } else {
        var store_bytes: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType align(32) = @ptrCast(store);
        const buf: *[@bitSizeOf(T) / @bitSizeOf(IntType)]IntType = @ptrFromInt(a);
        for (0..store_bytes.len, buf) |i, *b| {
            store_bytes[i] = std.mem.readInt(IntType, std.mem.asBytes(b), std.builtin.Endian.big);
        }
    }
}

pub const FdtReserveEntry = packed struct {
    address: u64,
    size: u64,
};

pub const FdtProp = struct {
    len: u32,
    nameoff: u32,
    value: [*:0]const u8,
};
