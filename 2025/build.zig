const std = @import("std");
const aoc = @import("aoc");

const YEAR = 2025;
var DAY: u5 = 1;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (b.args) |args| {
        DAY = std.fmt.parseInt(u5, args[0], 10) catch 1;
        std.debug.print("🎅🏼 Running day {d:0>2}\n", .{DAY});
    } else {
        // @TODO
        // try aoc.getToday();
    }

    // const cwd = try std.fs.cwd().realpathAlloc(b.allocator, ".");
    // try aoc.fetchInputData(b, target, optimize, cwd, YEAR, DAY);

    const dep_aoc = b.dependency("aoc", .{});
    const aoc_puzzleinput = dep_aoc.artifact("puzzle-input-helper");
    std.debug.print("{any}\n", .{@TypeOf(aoc_puzzleinput)});

    const cmd = b.addRunArtifact(aoc_puzzleinput);
    const arg_year = try std.fmt.allocPrint(b.allocator, "{d}", .{YEAR});
    defer b.allocator.free(arg_year);
    const arg_day = try std.fmt.allocPrint(b.allocator, "{d}", .{DAY});
    defer b.allocator.free(arg_day);
    cmd.addArg(arg_year);
    cmd.addArg(arg_day);
    const captured_output = cmd.captureStdOut(); // use this as anonymous import

    const src_name = try std.fmt.allocPrint(b.allocator, "day{d:0>2}.zig", .{DAY});
    defer b.allocator.free(src_name);
    const src_path = try std.fs.path.join(b.allocator, &.{ "src", src_name });
    defer b.allocator.free(src_path);
    const exe_name = try std.fmt.allocPrint(b.allocator, "aoc-{d}-day{d:0>2}", .{ YEAR, DAY });
    defer b.allocator.free(exe_name);

    _ = std.fs.cwd().openFile(src_path, .{}) catch {
        std.debug.print("{s} not found. Creating from template...\n", .{src_path});
        const contents = try aoc.createTemplate(b.allocator, YEAR, DAY);
        defer b.allocator.free(contents);
        std.debug.print("{s}\n", .{contents});
        const src_file = try std.fs.cwd().createFile(src_path, .{});
        defer src_file.close();
        try src_file.writeAll(contents);
    };

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(src_path),
            .optimize = optimize,
            .target = target,
        }),
    });
    b.installArtifact(exe);

    exe.root_module.addAnonymousImport("puzzle", .{ .root_source_file = captured_output });

    exe.root_module.addImport("aoc", dep_aoc.module("aoc"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Start the program");
    run_step.dependOn(&run_cmd.step);
}
