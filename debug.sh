#!/bin/sh
riscv64-elf-gdb zig-out/bin/kernel.elf -ex "set disassemble-next-line on" -ex "target remote :1234"
