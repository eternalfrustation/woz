const std = @import("std");
const builtin = @import("builtin");
pub const Header = struct {
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

    pub fn fromAddress(a: usize) !*Header {
        if (builtin.cpu.arch.endian() == std.builtin.Endian.big) {
            return @ptrFromInt(a);
        } else {
            const buf: *[@bitSizeOf(Header) / 32]u32 = @ptrFromInt(a);
            for (buf) |*b| {
                b.* = std.mem.readInt(u32, std.mem.asBytes(b), std.builtin.Endian.big);
            }
            return @ptrFromInt(@intFromPtr(buf.ptr));
        }
    }
};
