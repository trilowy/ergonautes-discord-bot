const std = @import("std");
const httpz = @import("httpz");
const log = @import("server/logger.zig");
const App = @import("server/state.zig").App;
const config_mod = @import("server/config.zig");
const Config = config_mod.Config;
const loadConfig = config_mod.loadConfig;
const handlers = @import("handlers.zig");
const DiscordClient = @import("DiscordClient.zig");
const AuthService = @import("AuthService.zig");
const CommandService = @import("CommandService.zig");

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

    // Register Discord commands at server startup
    try discord_client.registerCommandsToDiscord(init.gpa);

    const auth_service = try AuthService.init(config.discord);

    const command_service = CommandService{
        .arena = init.arena,
        .discord_client = &discord_client,
        .contrib_role_name = config.discord.contrib_role_name,
    };

    var app = App{
        .io = init.io,
        .auth_service = auth_service,
        .command_service = command_service,
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
