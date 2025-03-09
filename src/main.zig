// Using the entry point from init.S

const std = @import("std");

const traverser = @import("dtb/traverser.zig");
const debug = @import("opensbi/debug.zig");
const reset = @import("opensbi/reset.zig");

pub const panic = std.debug.FullPanic(kernelPanic);

fn kernelPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    _ = debug.print("Panic! \n") catch 0;
    _ = debug.print(msg) catch 0;
    while (true) {}
}

pub const std_options: std.Options = .{
    // This is the logging function used by `std.log`.
    .logFn = kLog,
};

/// This fking sucks, need to be improved
/// TODO: Implement a way to parse scope
fn kLog(
    comptime level: std.log.Level,
    // Scope
    comptime _: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // We could do anything we want here!
    // ...but actually, let's just call the default implementation.
    debug.print("kLog {");
    debug.print(level.asText());
    const message: [1000]u8 = undefined;

    std.fmt.bufPrint(message, format, args);

    const line: [1200]u8 = undefined;
    std.fmt.bufPrint(line, "kLog {}: {}\n", level.asText(), message);
}

fn strlen(str: [*:0]const u8) usize {
    var i: usize = 0;
    while (str[i] != 0) {
        i += 1;
    }
    return i;
}

export fn kmain() noreturn {
    const dtbp = asm (
        \\
        : [abc] "={t0}" (-> usize),
    );
    const dtb_header = traverser.GenericFromAddress(traverser.Header, u32, dtbp);
    const struct_dtp = dtbp + dtb_header.off_dt_struct;
    var mem_rsvmap = dtbp + dtb_header.off_mem_rsvmap;
    var mem_entry = traverser.GenericFromAddress(traverser.FdtReserveEntry, u64, mem_rsvmap);
    while (mem_entry.address != 0 and mem_entry.size != 0) {
        mem_rsvmap += @bitSizeOf(@TypeOf(mem_entry)) / 8;
        mem_entry = traverser.GenericFromAddress(traverser.FdtReserveEntry, u64, mem_rsvmap);
    }

    var offset: usize = 0;
    var tokenWithErr = traverser.RawFdtToken.FromAddress(struct_dtp + offset);
    while (tokenWithErr) |token| {
        switch (token) {
            traverser.RawFdtToken.FDT_END => {
                offset += 4;
                break;
            },
            traverser.RawFdtToken.FDT_END_NODE => {
                offset += 4;
            },
            traverser.RawFdtToken.FDT_NOOP => {
                offset += 4;
            },
            traverser.RawFdtToken.FDT_BEGIN => |begin_token| {
                const name_len = strlen(begin_token.name) + 1;
                offset += 4 + name_len + (4 - name_len % 4) % 4;
            },
            traverser.RawFdtToken.FDT_PROP => |prop_token| {
                offset += 4 + 8 + prop_token.value.len + (4 - prop_token.value.len % 4) % 4;
            },
        }
        tokenWithErr = traverser.RawFdtToken.FromAddress(struct_dtp + offset);
    } else |e| {
        _ = e catch unreachable;
    }

    _ = debug.print("\n\n\nHello, after parsing\n\n\n") catch 0;
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
