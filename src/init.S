.section .text

.global _entry

_entry:
	.option norvc

	.option push
	.option norelax
	la gp, global_pointer
	.option pop
	csrw satp, zero
	la sp, stack_top
	la t5, bss_start
	la t6, bss_end
	mv t0, a1

bss_clear:
	sd zero, (t5)
	addi t5, t5, 8
	bltu t5, t6, bss_clear

	tail kmain
	.end
