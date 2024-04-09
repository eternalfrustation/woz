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

    const kernel_path = b.fmt("{s}/{s}", .{ b.exe_dir, kernel.out_filename });
    const run_cmd_str = [_][]const u8{ "qemu-system-x86_64", "-kernel", kernel_path };

    const run_cmd = b.addSystemCommand(&run_cmd_str);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the kernel");

    run_step.dependOn(&run_cmd.step);
}
