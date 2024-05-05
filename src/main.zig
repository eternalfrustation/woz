const SERIAL_ADDR: *u8 = @ptrFromInt(0x10000000);

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ .section .init
        \\
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
    kprint_uart(str, str.len);
}

export fn kprint_uart(str: [*]const u8, len: usize) void {
    for (0..len) |i| {
        SERIAL_ADDR.* = str[i];
    }
}
