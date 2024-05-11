const debug = @import("opensbi/debug.zig");
const std = @import("std");
const traverser = @import("dtb/traverser.zig");
const reset = @import("opensbi/reset.zig");

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ .option norvc
        \\
        \\
        \\ .option push
        \\ .option norelax
        \\      la gp, global_pointer
        \\  .option pop
        \\      csrw satp, zero
        \\      la sp, stack_top
        \\      la t5, bss_start
        \\      la t6, bss_end
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

export fn kmain() noreturn {
    const dtbp = asm (
        \\
        : [dtbp] "={a1}" (-> usize),
    );
    _ = debug.printHex(usize, dtbp) catch unreachable;

    var dtb_header: traverser.Header = undefined;
    var printBuffer: [256]u8 = undefined;
    traverser.FromAddress(@TypeOf(dtb_header), u32, &dtb_header, dtbp);
    _ = debug.write_char('\n') catch unreachable;
    _ = debug.printHex(traverser.Header, dtb_header) catch unreachable;
    var out = std.fmt.bufPrint(&printBuffer, "\nHeader: \n\tmagic: {},\n\ttotal_size: {},\n\toff_dt_struct: {},\n\toff_dt_strings: {},\n\toff_mem_rsvmap: {},\n\tversion: {},\n\tlast_comp_version: {},\n\tboot_cpuid_phys: {},\n\tsize_dt_strings: {},\n\tsize_st_struct: {}\n", dtb_header) catch unreachable;
    _ = debug.print(out) catch 0;
    _ = debug.print("Hello") catch 0;
    const struct_dtp = dtbp + dtb_header.off_dt_struct;
    _ = struct_dtp; // autofix
    const strings_dtp = dtbp + dtb_header.off_dt_strings;
    _ = strings_dtp; // autofix
    var mem_rsvmap = dtbp + dtb_header.off_mem_rsvmap;
    var mem_entry: traverser.FdtReserveEntry = undefined;
    traverser.FromAddress(@TypeOf(mem_entry), u64, &mem_entry, mem_rsvmap);
    while (mem_entry.address != 0 and mem_entry.size != 0) {
        out = std.fmt.bufPrint(&printBuffer, "\nFdtReserveEntry: \n\taddress: {},\n\tsize: {}\n", mem_entry) catch unreachable;
        _ = debug.print(out) catch 0;
        mem_rsvmap += @bitSizeOf(@TypeOf(mem_entry)) / 8;
        traverser.FromAddress(@TypeOf(mem_entry), u64, &mem_entry, mem_rsvmap);
    }
    _ = debug.print("Hello2") catch 0;
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
