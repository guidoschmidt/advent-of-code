const std = @import("std");

const BuildTargetResults = struct {
    exe: *std.Build.Step.Compile,
    tests: *std.Build.Step.Compile,
};

fn createBuildTarget(b: *std.Build,
                     target: std.Build.ResolvedTarget,
                     optimize: std.builtin.OptimizeMode,
                     aoc_module: *std.Build.Module,
                     libs: *std.StringHashMap(*std.Build.Module),
                     year: u16,
                     day: usize) !BuildTargetResults {
    var src_buf: [32]u8 = undefined;
    const source_file = try std.fmt.bufPrint(&src_buf, "{d}/day{d}.zig", .{ year, day });
    var name_buf: [32]u8 = undefined;
    const name = try std.fmt.bufPrint(&name_buf, "{d}-{d}", .{ year, day });
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(source_file),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("aoc", aoc_module);

    var libs_it = libs.iterator();
    while (libs_it.next()) |lib| {
        exe.root_module.addImport(lib.key_ptr.*, lib.value_ptr.*);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = b.path(source_file),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    return .{
        .exe = exe,
        .tests = unit_tests,
    };
}

pub fn build(b: *std.Build) !void {
    const YEAR: usize = 2023;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const aoc_module = b.addModule("aoc", .{
        .root_source_file = b.path("./aoc/root.zig"),
        .optimize = optimize,
        .target = target
    });

    var libs = std.StringHashMap(*std.Build.Module).init(b.allocator);

    const lib_names = .{"ppm", "math", "svg", "term"};
    inline for (0..lib_names.len) |i| {
        const lib_name = lib_names[i];
        const module = b.addModule(lib_name, .{
            .root_source_file = b.path("./libs/" ++ lib_name ++ ".zig"),
            .optimize = optimize,
            .target = target,
        });
        try libs.put(lib_name, module);
    }


    const in = std.io.getStdIn();
    var buf = std.io.bufferedReader(in.reader());

    // Get the Reader interface from BufferedReader
    var r = buf.reader();

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        const day = std.fmt.parseInt(u8, args[0], 10) catch 1;
        const res = try createBuildTarget(b, target, optimize, aoc_module, &libs, YEAR, day);

        const run_cmd = b.addRunArtifact(res.exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(try std.fmt.allocPrint(b.allocator, "run", .{}),
                                try std.fmt.allocPrint(b.allocator, "Run {d} of {d}", .{ day, YEAR }));
        run_step.dependOn(&run_cmd.step);

        // Testing
        const run_unit_tests = b.addRunArtifact(res.tests);
        const test_step = b.step(try std.fmt.allocPrint(b.allocator, "test",  .{ }),
                                 try std.fmt.allocPrint(b.allocator, "Run test cases for {d} of {d}", .{ day, YEAR }));
        test_step.dependOn(&run_unit_tests.step);
        return;
    }

    for (1..25) |day| {
        _ = try createBuildTarget(b, target, optimize, aoc_module, &libs, YEAR, day);
    }

    // Interactive prompt
    if (false) {
        // If no argument was given, ask the user which day should be build/run
        std.debug.print("\nWhich day should be build/run [1 - 24]? ", .{});
        // Ideally we would want to issue more than one read
        // otherwise there is no point in buffering.
        var msg_buf: [4096]u8 = undefined;
        const input = r.readUntilDelimiterOrEof(&msg_buf, '\n') catch "";
        if (input) |input_txt| {
            const day = std.fmt.parseInt(u8, input_txt, 10) catch {
                std.debug.print("\nPlease give a number between 1 and 24\n\n", .{});
                return;
            };
            std.debug.print("Selected day {d}\n~ Compiling...\n", .{day});
            try createBuildTarget(b, target, optimize, aoc_module, &libs, YEAR, day);
        }
    }
}
