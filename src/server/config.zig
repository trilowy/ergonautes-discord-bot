const std = @import("std");
const getEnvVarOwned = std.process.getEnvVarOwned;
const parseInt = std.fmt.parseInt;
const logz = @import("logz");

/// Global configuration
pub const Config = struct {
    /// Server configuration
    server: ServerConfig,

    /// Logger configuration
    log: LogConfig,

    /// Discord configuration
    discord: DiscordConfig,
};

/// Server configuration
const ServerConfig = struct {
    /// Server port
    port: u16,
};

/// Logger configuration
pub const LogConfig = struct {
    /// Logging formatted in JSON or not
    json_format: bool,

    /// Logging level of the application
    level: logz.Level,
};

/// Discord configuration
pub const DiscordConfig = struct {
    /// Bot app ID
    app_id: []const u8,

    /// Bot public key
    public_key: []const u8,

    /// Discord token
    token: []const u8,
};

const separator = "__";
const prefix = "EDB" ++ separator;

pub fn loadConfig(allocator: std.mem.Allocator) !Config {
    var config: Config = @import("config_default.zon");

    const server = prefix ++ "SERVER" ++ separator;

    if (getEnvVarOwned(allocator, server ++ "PORT")) |port| {
        config.server.port = try parseInt(u16, port, 10);
    } else |_| {}

    const log = prefix ++ "LOG" ++ separator;

    if (getEnvVarOwned(allocator, log ++ "JSON_FORMAT")) |json_format| {
        config.log.json_format =
            if (std.mem.eql(u8, json_format, "true"))
                true
            else
                false;
    } else |_| {}

    if (getEnvVarOwned(allocator, log ++ "LEVEL")) |level| {
        config.log.level = std.meta.stringToEnum(logz.Level, level) orelse {
            return error.InvalidLogLevel;
        };
    } else |_| {}

    const discord = prefix ++ "DISCORD" ++ separator;

    if (getEnvVarOwned(allocator, discord ++ "APP_ID")) |app_id| {
        config.discord.app_id = app_id;
    } else |_| {}

    if (getEnvVarOwned(allocator, discord ++ "PUBLIC_KEY")) |public_key| {
        config.discord.public_key = public_key;
    } else |_| {}

    if (getEnvVarOwned(allocator, discord ++ "TOKEN")) |token| {
        config.discord.token = token;
    } else |_| {}

    return config;
}
