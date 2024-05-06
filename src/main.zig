const uart = @import("uart.zig");
export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ .option norvc
        \\
        \\ .type start, @function
        \\ .global start
        \\
        \\ .option push
        \\ .option norelax
        \\      la gp, global_pointer
        \\  .option pop
        \\      csrw satp, zero
        \\      la sp, stack_top
        \\          la t5, bss_start
        \\          la t6, bss_end
        \\      bss_clear:
        \\          sd zero, (t5)
        \\          addi t5, t5, 8
        \\          bltu t5, t6, bss_clear
        \\
        \\          la t0, kmain
        \\          csrw mepc, t0
        \\          tail kmain
        \\      .end
    );
    while (true) {}
}

export fn kmain() void {
    const str = "Hello world!";
    uart.kprint_uart(str, str.len);

    while (true) {
        while (uart.kreadc_uart()) |c| {
            uart.kputc_uart(c);
        }
    }
}
