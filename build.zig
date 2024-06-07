const std = @import("std");

fn createBuildTarget(b: *std.Build, day: u8) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var source_file_buf: [32]u8 = undefined;
    const source_file = std.fmt.bufPrint(&source_file_buf,
                                         "src/day{d}.zig", .{ day }) catch "src/day1.zig";
    const exe = b.addExecutable(.{
        .name = "advent-of-code",
        .root_source_file =  b.path(source_file),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);


    // Testing
    const unit_tests = b.addTest(.{
        .root_source_file = b.path(source_file),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run test cases");
    test_step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) void {

   const in = std.io.getStdIn();
    var buf = std.io.bufferedReader(in.reader());

    // Get the Reader interface from BufferedReader
    var r = buf.reader();

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        const day = std.fmt.parseInt(u8, args[0], 10) catch 1;
        createBuildTarget(b, day);
        return;
    }

    // If no argument was given, ask the user which day should be build/run
    std.debug.print("\nWhich day should be build/run [1 - 24]? ", .{});
    // Ideally we would want to issue more than one read
    // otherwise there is no point in buffering.
    var msg_buf: [4096]u8 = undefined;
    const input = r.readUntilDelimiterOrEof(&msg_buf, '\n') catch "";
    if (input) |input_txt| {
        const day = std.fmt.parseInt(u8, input_txt, 10) catch {
            std.debug.print("\nPlease give a number between 1 and 24", .{});
            return;
        };
        std.debug.print("Selected day {d}\n~ Compiling...\n", .{ day });
        createBuildTarget(b, day);
    }
}
