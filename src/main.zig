const debug = @import("opensbi/debug.zig");
const std = @import("std");
const traverser = @import("dtb/traverser.zig");
const reset = @import("opensbi/reset.zig");

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ .option norvc
        \\
        \\ .option push
        \\ .option norelax
        \\      la gp, global_pointer
        \\  .option pop
        \\      csrw satp, zero
        \\      la sp, stack_top
        \\      la t5, bss_start
        \\      la t6, bss_end
        \\      mv t0, a1
        \\
        \\      bss_clear:
        \\          sd zero, (t5)
        \\          addi t5, t5, 8
        \\          bltu t5, t6, bss_clear
        \\
        \\          tail kmain
        \\      .end
    );
    while (true) {}
}

fn strlen(str: [*:0]const u8) usize {
    var i: usize = 0;
    while (str[i] != 0) {
        i += 1;
    }
    return i;
}

export fn kmain() noreturn {
    const dtbp = asm (
        \\
        : [abc] "={t0}" (-> usize),
    );
    _ = debug.printHex(usize, dtbp) catch unreachable;

    var printBuffer: [2048]u8 = undefined;
    const dtb_header = traverser.GenericFromAddress(traverser.Header, u32, dtbp);
    _ = debug.write_char('\n') catch unreachable;
    _ = debug.printHex(traverser.Header, dtb_header) catch unreachable;
    var out = std.fmt.bufPrint(&printBuffer, "\nHeader: \n\tmagic: 0x{X},\n\ttotal_size: 0x{X},\n\toff_dt_struct: 0x{X},\n\toff_dt_strings: 0x{X},\n\toff_mem_rsvmap: 0x{X},\n\tversion: 0x{X},\n\tlast_comp_version: 0x{X},\n\tboot_cpuid_phys: 0x{X},\n\tsize_dt_strings: 0x{X},\n\tsize_st_struct: 0x{X}\n", dtb_header) catch unreachable;
    _ = debug.print(out) catch 0;
    out = std.fmt.bufPrint(&printBuffer, "Base Address of dtb: {X}\n", .{dtbp}) catch unreachable;
    _ = debug.print(out) catch 0;
    const struct_dtp = dtbp + dtb_header.off_dt_struct;
    const strings_dtp = dtbp + dtb_header.off_dt_strings;
    _ = strings_dtp; // autofix
    var mem_rsvmap = dtbp + dtb_header.off_mem_rsvmap;
    out = std.fmt.bufPrint(&printBuffer, "Memory Reserve Map Address of dtb: {X}\n", .{mem_rsvmap}) catch unreachable;
    _ = debug.print(out) catch 0;
    const mem_entries: *const [64]u8 = @ptrFromInt(mem_rsvmap);
    out = std.fmt.bufPrint(&printBuffer, "Memory discriptor sectio of dtb: {X}\n", .{mem_rsvmap}) catch unreachable;
    _ = debug.print(out) catch 0;
    _ = debug.printHex([64]u8, mem_entries.*) catch unreachable;
    var mem_entry = traverser.GenericFromAddress(traverser.FdtReserveEntry, u64, mem_rsvmap);
    while (mem_entry.address != 0 and mem_entry.size != 0) {
        out = std.fmt.bufPrint(&printBuffer, "\nFdtReserveEntry: \n\taddress: {},\n\tsize: {}\n", mem_entry) catch unreachable;
        _ = debug.print(out) catch 0;
        mem_rsvmap += @bitSizeOf(@TypeOf(mem_entry)) / 8;
        mem_entry = traverser.GenericFromAddress(traverser.FdtReserveEntry, u64, mem_rsvmap);
    }

    var offset: usize = 0;
    out = std.fmt.bufPrint(&printBuffer, "Data address of current dtb: {X}\n", .{struct_dtp + offset}) catch unreachable;
    _ = debug.print(out) catch 0;
    var tokenWithErr = traverser.RawFdtToken.FromAddress(struct_dtp + offset);
    while (tokenWithErr) |token| {
        switch (token) {
            traverser.RawFdtToken.FDT_END => {
                out = std.fmt.bufPrint(&printBuffer, "\nFDT_END\n", .{}) catch unreachable;
                offset += 4;
                break;
            },
            traverser.RawFdtToken.FDT_END_NODE => {
                out = std.fmt.bufPrint(&printBuffer, "\nFDT_END_NODE\n", .{}) catch unreachable;
                offset += 4;
            },
            traverser.RawFdtToken.FDT_NOOP => {
                out = std.fmt.bufPrint(&printBuffer, "\nFDT_NOOP\n", .{}) catch unreachable;
                offset += 4;
            },
            traverser.RawFdtToken.FDT_BEGIN => |begin_token| {
                out = std.fmt.bufPrint(&printBuffer, "\nFDT_BEGIN: {s}\n", .{begin_token.name}) catch unreachable;
                const name_len = strlen(begin_token.name) + 1;
                offset += 4 + name_len + (4 - name_len % 4) % 4;
            },
            traverser.RawFdtToken.FDT_PROP => |prop_token| {
                out = std.fmt.bufPrint(&printBuffer, "\nFDT_PROP, {}\n", .{prop_token}) catch unreachable;
                offset += 4 + 8 + prop_token.value.len + (4 - prop_token.value.len % 4) % 4;
            },
        }
        _ = debug.print(out) catch 0;
        out = std.fmt.bufPrint(&printBuffer, "Data address of current dtb: {X}\n", .{struct_dtp + offset}) catch unreachable;
        _ = debug.print(out) catch 0;
        tokenWithErr = traverser.RawFdtToken.FromAddress(struct_dtp + offset);
    } else |e| {
        out = std.fmt.bufPrint(&printBuffer, "\nError while parsing dtb: {}\n", .{e}) catch unreachable;
        _ = debug.print(out) catch 0;
    }

    out = std.fmt.bufPrint(&printBuffer, "\nExpected size of structs: {}, Size parsed: {}\n", .{ dtb_header.size_dt_struct, offset }) catch unreachable;
    _ = debug.print(out) catch 0;

    _ = debug.print("\n\n\nHello, after parsing\n\n\n") catch 0;
    while (true) {
        var a = [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        _ = debug.read_str(&a) catch continue;
        for (a) |c| {
            if (c == ';') {
                _ = reset.system_reset(reset.ResetType.COLD_REBOOT, reset.ResetReason.NO_REASON) catch {
                    _ = debug.print("\nCouldn't restart\n") catch unreachable;
                };
            }
        }
        _ = debug.print(&a) catch continue;
    }
}
