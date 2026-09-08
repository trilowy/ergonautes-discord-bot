const std = @import("std");
const logz = @import("logz");
const LogConfig = @import("config.zig").LogConfig;

pub fn init(
    io: std.Io,
    allocator: std.mem.Allocator,
    config: LogConfig,
) !void {
    const encoding: logz.Config.Encoding =
        if (config.json_format)
            .json
        else
            .logfmt;

    try logz.setup(io, allocator, .{
        .level = config.level,
        .encoding = encoding,
    });
}

pub fn deinit() void {
    logz.deinit();
}

pub fn debug(comptime message: []const u8, values: anytype) void {
    logz.debug().fmt("msg", message, values).log();
}

pub fn info(comptime message: []const u8, values: anytype) void {
    logz.info().fmt("msg", message, values).log();
}

pub fn warn(comptime message: []const u8, values: anytype) void {
    logz.warn().fmt("msg", message, values).log();
}

pub fn err(comptime message: []const u8, values: anytype) void {
    logz.err().fmt("msg", message, values).log();
}
