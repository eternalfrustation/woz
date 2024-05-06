// a7 has the extension id
// a6 has the function id
// a0, a1, a2... have the arguments to the function
// ecall to finally call the function
// a0 has the return code
// a1 has the return value
pub fn kdebug_print(s: []const u8) isize {
    return asm (
        \\ li a7, 0x4442434E
        \\ li a6, 0x0
        \\ li a2, 0
        \\ ecall
        : [ret] "={a0}" (-> isize),
        : [len] "{a0}" (s.len),
          [ptr] "{a1}" (s.ptr),
    );
}
