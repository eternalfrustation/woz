pub const SBIError = error{
    FAILED,
    NOT_SUPPORTED,
    INVALID_PARAM,
    DENIED,
    INVALID_ADDRESS,
    ALREADY_AVAILABLE,
    ALREADY_STARTED,
    ALREADY_STOPPED,
    NO_SHMEM,
    UNKNOWN,
};

// x should only range from -1 to -9
// Anything else will cause undefined behaviour
pub fn err_from_int(x: isize) SBIError {
    return switch (x) {
        -1 => SBIError.FAILED,
        -2 => SBIError.NOT_SUPPORTED,
        -3 => SBIError.INVALID_PARAM,
        -4 => SBIError.DENIED,
        -5 => SBIError.INVALID_ADDRESS,
        -6 => SBIError.ALREADY_AVAILABLE,
        -7 => SBIError.ALREADY_STARTED,
        -8 => SBIError.ALREADY_STOPPED,
        -9 => SBIError.NO_SHMEM,
        else => unreachable,
    };
}
