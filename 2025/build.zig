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

    const arg_year = try std.fmt.allocPrint(b.allocator, "{d}", .{YEAR});
    defer b.allocator.free(arg_year);

    const arg_day = try std.fmt.allocPrint(b.allocator, "{d}", .{DAY});
    defer b.allocator.free(arg_day);

    const arg_input_type_puzzle = try std.fmt.allocPrint(b.allocator, "{d}", .{
        @intFromEnum(aoc.types.PuzzleInput.PUZZLE),
    });
    defer b.allocator.free(arg_input_type_puzzle);

    const arg_input_type_example = try std.fmt.allocPrint(b.allocator, "{d}", .{
        @intFromEnum(aoc.types.PuzzleInput.EXAMPLE),
    });
    defer b.allocator.free(arg_input_type_puzzle);

    const cmd_puzzle_input = b.addRunArtifact(aoc_puzzleinput);
    cmd_puzzle_input.addArgs(&.{
        arg_input_type_puzzle,
        arg_year,
        arg_day,
        "input",
    });
    const captured_output_puzzle = cmd_puzzle_input.captureStdOut(); // use this as anonymous import

    const cmd_example_input = b.addRunArtifact(aoc_puzzleinput);
    cmd_example_input.addArgs(&.{
        arg_input_type_example,
        arg_year,
        arg_day,
        "input",
    });
    const captured_output_example = cmd_example_input.captureStdOut(); // use this as anonymous import

    const src_name = try std.fmt.allocPrint(b.allocator, "day{d:0>2}.zig", .{DAY});
    defer b.allocator.free(src_name);
    const src_path = try std.fs.path.join(b.allocator, &.{ "src", src_name });
    defer b.allocator.free(src_path);
    const exe_name = try std.fmt.allocPrint(b.allocator, "aoc-{d}-day{d:0>2}", .{ YEAR, DAY });
    defer b.allocator.free(exe_name);

    _ = std.fs.cwd().openFile(src_path, .{}) catch {
        std.debug.print("{s} not found. Creating from template...\n", .{src_path});
        const contents = try aoc.createTemplate(b.allocator, DAY);
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

    const puzzle_input_name = try std.fmt.allocPrint(b.allocator, "puzzle-{d:0>2}", .{DAY});
    defer b.allocator.free(puzzle_input_name);
    exe.root_module.addAnonymousImport(puzzle_input_name, .{
        .root_source_file = captured_output_puzzle,
    });

    const example_input_name = try std.fmt.allocPrint(b.allocator, "example-{d:0>2}", .{DAY});
    defer b.allocator.free(puzzle_input_name);
    exe.root_module.addAnonymousImport(example_input_name, .{
        .root_source_file = captured_output_example,
    });

    exe.root_module.addImport("aoc", dep_aoc.module("aoc"));

    const dep_libs = b.dependency("libs", .{});
    exe.root_module.addImport("libs", dep_libs.module("libs"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Start the program");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(src_path),
            .target = target,
            .optimize = optimize,
        }),
    });
    // tests.root_module.addAnonymousImport(example_input_name, .{
    //     .root_source_file = b.path(example_input_name),
    // });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
