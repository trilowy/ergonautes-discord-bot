const std = @import("std");
const httpz = @import("httpz");
const curl = @import("curl");
const log = @import("server/logger.zig");
const App = @import("server/state.zig").App;
const config_mod = @import("server/config.zig");
const Config = config_mod.Config;
const loadConfig = config_mod.loadConfig;
const handlers = @import("handlers.zig");
const DiscordClient = @import("DiscordClient.zig");

pub fn main(init: std.process.Init) !void {
    const config = try loadConfig(init.environ_map);

    try log.init(init.io, init.gpa, config.log);
    defer log.deinit();

    var discord_client = try DiscordClient.init(
        init.io,
        init.gpa,
        config.discord,
    );
    defer discord_client.deinit();

    try discord_client.registerCommandsToDiscord(init.gpa);

    var app = App{
        .io = init.io,
        .discord_config = config.discord,
    };

    var server = try httpz.Server(*App).init(
        init.io,
        init.gpa,
        .{ .address = .localhost(config.server.port) },
        &app,
    );
    defer {
        // Clean shutdown, finishes serving any live requests
        log.info("Shutting down server gracefully", .{});
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/monitoring/health", handlers.health, .{});
    router.post("/interactions", handlers.interactions, .{});

    log.info("Listening on http://127.0.0.1:3000", .{});
    try server.listen();
}
