const std = @import("std");
const Builder = @import("std").build.Builder;
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;
const LazyPath = @import("std").Build.LazyPath;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const features = Target.x86.Feature;
    var disabledFeatures = Feature.Set.empty;
    var enabledFeatures = Feature.Set.empty;
    disabledFeatures.addFeature(@intFromEnum(features.mmx));
    disabledFeatures.addFeature(@intFromEnum(features.sse));
    disabledFeatures.addFeature(@intFromEnum(features.sse2));
    disabledFeatures.addFeature(@intFromEnum(features.avx));
    disabledFeatures.addFeature(@intFromEnum(features.avx2));
    enabledFeatures.addFeature(@intFromEnum(features.soft_float));

    const arch = Target.Cpu.Arch.x86;
    const osTag = Target.Os.Tag.freestanding;
    const abi = Target.Abi.none;
    const targetQuery = CrossTarget{ .cpu_arch = arch, .os_tag = osTag, .abi = abi, .cpu_features_sub = disabledFeatures, .cpu_features_add = enabledFeatures };

    const target = Target{ .abi = abi, .cpu = Target.Cpu.baseline(arch), .os = Target.Os{ .tag = osTag, .version_range = Target.Os.VersionRange.default(osTag, arch) }, .ofmt = Target.ObjectFormat.elf };
    const kernel = b.addExecutable(.{ .name = "kernel.elf", .root_source_file = LazyPath{ .path = "src/main.zig" }, .target = .{ .query = targetQuery, .result = target } });
    kernel.setLinkerScript(.{ .path = "src/linker.ld" });
    b.installArtifact(kernel);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.step);

    //    const iso_dir = b.fmt("{s}/iso_root", .{b.cache_root});
    const iso_dir = std.mem.concat(b.allocator, u8, &[_][]const u8{ b.cache_root.path.?, "/iso_root" }) catch unreachable;
    const kernel_path = std.mem.concat(b.allocator, u8, &[_][]const u8{ b.install_path, "/bin/", kernel.out_filename }) catch unreachable;
    const iso_path = b.fmt("{s}/disk.iso", .{b.exe_dir});

    const iso_cmd_str = &[_][]const u8{ "/bin/sh", "-c", std.mem.concat(b.allocator, u8, &[_][]const u8{ "mkdir -p ", iso_dir, " && ", "cp ", kernel_path, " ", iso_dir, " && ", "cp src/grub.cfg ", iso_dir, " && ", "grub-mkrescue -o ", iso_path, " ", iso_dir }) catch unreachable };
    const iso_cmd = b.addSystemCommand(iso_cmd_str);
    iso_cmd.step.dependOn(kernel_step);

    const iso_step = b.step("iso", "Build Iso");
    iso_step.dependOn(&iso_cmd.step);
    b.default_step.dependOn(iso_step);

    const run_cmd_str = [_][]const u8{ "qemu-system-i386", "-cdrom", iso_path, "-debugcon", "stdio", "-vga", "virtio", "-m", "4G", "-machine", "q35", "-no-reboot", "-no-shutdown" };

    const run_cmd = b.addSystemCommand(&run_cmd_str);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the kernel");

    run_step.dependOn(&run_cmd.step);
}
