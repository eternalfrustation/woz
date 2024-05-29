// Built with zig 0.12.0
const std = @import("std");
const Builder = @import("std").build.Builder;
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;
const LazyPath = @import("std").Build.LazyPath;
const CodeModel = @import("std").builtin.CodeModel;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const features = Target.riscv.Feature;
    var disabledFeatures = Feature.Set.empty;
    var enabledFeatures = Feature.Set.empty;
    disabledFeatures.addFeature(@intFromEnum(features.v));
    enabledFeatures.addFeature(@intFromEnum(features.m));
    enabledFeatures.addFeature(@intFromEnum(features.a));
    enabledFeatures.addFeature(@intFromEnum(features.c));
    enabledFeatures.addFeature(@intFromEnum(features.zicsr));

    const arch = Target.Cpu.Arch.riscv64;
    const osTag = Target.Os.Tag.freestanding;
    const abi = Target.Abi.none;
    const targetQuery = CrossTarget{ .cpu_arch = arch, .os_tag = osTag, .abi = abi, .cpu_features_sub = disabledFeatures, .cpu_features_add = enabledFeatures };

    const target = Target{ .abi = abi, .cpu = Target.Cpu.baseline(arch), .os = Target.Os{ .tag = osTag, .version_range = Target.Os.VersionRange.default(osTag, arch) }, .ofmt = Target.ObjectFormat.elf };
    const kernel = b.addExecutable(.{ .name = "kernel.elf", .root_source_file = LazyPath{ .path = "src/main.zig" }, .target = .{ .query = targetQuery, .result = target }, .code_model = CodeModel.medium });
    kernel.setLinkerScript(.{ .path = "src/linker.ld" });
    b.installArtifact(kernel);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.step);

    const kernel_path = b.fmt("{s}/{s}", .{ b.exe_dir, kernel.out_filename });
    const hda_step = b.step("init_hda", "Init HDA");
    const hda_path = b.fmt("{s}/hdd.img", .{b.exe_dir});
    const hda = b.addSystemCommand(&[_][]const u8{ "qemu-img", "create", "-f", "qcow2", hda_path, "100M" });
    hda.step.dependOn(b.getInstallStep());
    hda_step.dependOn(&hda.step);
    const run_cmd_str = [_][]const u8{ "qemu-system-riscv64", "-hda", hda_path, "-device", "VGA", "-s", "-S", "-chardev", "stdio,id=char0,logfile=serial.log,signal=off", "-serial", "chardev:char0", "-machine", "virt", "-smp", "4", "-m", "2G", "-kernel", kernel_path, "-object", "rng-random,filename=/dev/urandom,id=rng0", "-device", "virtio-rng-device,rng=rng0", "-device", "virtio-net-device,netdev=usernet", "-netdev", "user,id=usernet,hostfwd=tcp::10000-:22" };

    const run_cmd = b.addSystemCommand(&run_cmd_str);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the kernel");

    run_step.dependOn(&run_cmd.step);
}
