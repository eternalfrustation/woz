ENTRY(_start)


SECTIONS {
	. = 0x82000000;
	.text : ALIGN(4K) {
		*(.text)
	}

	.bss : ALIGN(4K) {
		PROVIDE(bss_start = .);
		*(.bss);
		. += 1M;
		PROVIDE(stack_top = .);
		. += 1M;
		PROVIDE(global_pointer = .);
		PROVIDE(bss_end = .);
	}

	.rodata : ALIGN(4K) {
		*(.rodata)
	}

	.data : ALIGN(4K) {
		*(.data)
	}

}
