#!/bin/sh
gdb-multiarch zig-out/bin/kernel.elf -ex "set architecture riscv:rv64" -ex "set disassemble-next-line on" -ex "target remote :1234"
