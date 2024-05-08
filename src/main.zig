const debug = @import("opensbi/debug.zig");
const Header = @import("dtb/traverser.zig").Header;
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
        \\       la t6, bss_end
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

    const h = Header.fromAddress(dtbp) catch unreachable;
    _ = debug.write_char('\n') catch unreachable;
    _ = debug.printHex(Header, h.*) catch unreachable;
    _ = debug.print("Hello") catch 0;
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
