const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Dependencies
    const dep_opts = .{
        .target = target,
        .optimize = optimize,
    };

    // Add documentation into binary
    const doc_gen_path = generateDocumentations(b);
    const doc_gen = b.createModule(.{
        .root_source_file = doc_gen_path,
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("doc", doc_gen);

    const httpz = b.dependency("httpz", dep_opts);
    exe_mod.addImport("httpz", httpz.module("httpz"));

    const logz = b.dependency("logz", dep_opts);
    exe_mod.addImport("logz", logz.module("logz"));

    // This creates another `std.Build.Step.Compile`, but this one builds an executable
    // rather than a static library.
    const exe = b.addExecutable(.{
        .name = "ergonautes_discord_bot",
        .root_module = exe_mod,
    });

    // Check step for the LSP without install
    const check = b.step("check", "Check if it compiles");
    check.dependOn(&exe.step);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn generateDocumentations(b: *std.Build) std.Build.LazyPath {
    const io = b.graph.io;

    var doc_dir = b.build_root.handle.openDir(io, "doc", .{ .iterate = true }) catch |err| {
        std.debug.panic("Failed to open 'doc' dir: {}", .{err});
    };
    defer doc_dir.close(io);

    var zig_file = std.ArrayList(u8).empty;
    defer zig_file.deinit(b.allocator);

    zig_file.appendSlice(b.allocator,
        \\pub const Documentation = struct {
        \\    name: []const u8,
        \\    content: []const u8,
        \\};
        \\
        \\pub const documentations = &[_]Documentation{
        \\
    ) catch @panic("Out of memory");

    var it = doc_dir.iterate();

    while (it.next(io) catch |err| {
        std.debug.panic("Failed to iterate 'doc' dir: {}", .{err});
    }) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        if (!std.mem.endsWith(u8, entry.name, ".md")) {
            continue;
        }

        const name = entry.name[0 .. entry.name.len - ".md".len];

        const content = doc_dir.readFileAlloc(
            io,
            entry.name,
            b.allocator,
            .unlimited,
        ) catch |err| {
            std.debug.panic("Failed to read doc/{s}: {}", .{ entry.name, err });
        };
        defer b.allocator.free(content);

        const escaped_content = escapeZigString(b.allocator, content) catch @panic("Out of memory");
        defer b.allocator.free(escaped_content);

        const doc = std.fmt.allocPrint(
            b.allocator,
            \\    .{{
            \\        .name = "{s}",
            \\        .content = "{s}",
            \\    }},
            \\
        ,
            .{ name, escaped_content },
        ) catch @panic("Out of memory");
        defer b.allocator.free(doc);

        zig_file.appendSlice(b.allocator, doc) catch @panic("Out of memory");
    }

    zig_file.appendSlice(b.allocator,
        \\};
        \\
    ) catch @panic("Out of memory");

    return b.addWriteFiles().add("doc_gen.zig", zig_file.items);
}

fn escapeZigString(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    var escaped = std.ArrayList(u8).empty;
    errdefer escaped.deinit(allocator);

    for (content) |c| {
        switch (c) {
            '"' => try escaped.appendSlice(allocator, "\\\""),
            '\\' => try escaped.appendSlice(allocator, "\\\\"),
            '\n' => try escaped.appendSlice(allocator, "\\n"),
            '\r' => try escaped.appendSlice(allocator, "\\r"),
            '\t' => try escaped.appendSlice(allocator, "\\t"),
            else => try escaped.append(allocator, c),
        }
    }

    return escaped.toOwnedSlice(allocator);
}
