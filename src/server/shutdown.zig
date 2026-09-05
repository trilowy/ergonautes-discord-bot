const std = @import("std");
const httpz = @import("httpz");
const App = @import("state.zig").App;
const log = @import("logger.zig");

var server_instance: ?*httpz.Server(*App) = null;

/// Stop gracefully the server on SIGINT (ctrl-C)
pub fn setGracefulShutdown(server: *httpz.Server(*App)) void {
    server_instance = server;

    const action = std.posix.Sigaction{
        .handler = .{ .handler = shutdown },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.INT, &action, null);
    std.posix.sigaction(std.posix.SIG.TERM, &action, null);
}

/// Stop gracefully the server on SIGINT (ctrl-C)
fn shutdown(_: c_int) callconv(.c) void {
    // Clean shutdown, finishes serving any live request
    log.info("Shutting down server gracefully", .{});
    if (server_instance) |server| {
        server_instance = null;
        server.stop();
        server.deinit();
    }
}
