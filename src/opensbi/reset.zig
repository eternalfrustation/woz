const common = @import("../opensbi.zig");

pub const ResetType = enum(u32) {
    SHUTDOWN = 0x0,
    COLD_REBOOT = 0x1,
    WARM_REBOOT = 0x2,
};

pub const ResetReason = enum(u32) { NO_REASON = 0x0, SYSTEM_FAILURE = 0x1 };

pub fn system_reset(reset_type: ResetType, reset_reason: ResetReason) !noreturn {
    const err_code = asm (
        \\ li a7, 0x53525354
        \\ li a6, 0x0
        \\ li a2, 0
        \\ ecall
        : [err] "={a0}" (-> isize),
        : [typ] "{a0}" (reset_type),
          [rsn] "{a1}" (reset_reason),
    );
    return switch (err_code) {
        -9...-1 => common.err_from_int(err_code),
        else => unreachable,
    };
}
