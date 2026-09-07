const std = @import("std");
const httpz = @import("httpz");
const log = @import("server/logger.zig");
const App = @import("server/state.zig").App;
const config_mod = @import("server/config.zig");
const Config = config_mod.Config;
const loadConfig = config_mod.loadConfig;
const setGracefulShutdown = @import("server/shutdown.zig").setGracefulShutdown;
const handlers = @import("handlers.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_allocator.allocator();
    defer _ = debug_allocator.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const config = try loadConfig(arena.allocator());

    try log.init(allocator, config.log);
    defer log.deinit();

    var app = App{
        .discord_config = config.discord,
    };

    var server = try httpz.Server(*App).init(
        allocator,
        .{ .address = .localhost(config.server.port) },
        &app,
    );
    setGracefulShutdown(&server);

    var router = try server.router(.{});

    router.get("/monitoring/health", handlers.health, .{});
    router.get("/hello", handlers.hello, .{});

    log.info("Listening on http://127.0.0.1:3000", .{});
    try server.listen();
}
