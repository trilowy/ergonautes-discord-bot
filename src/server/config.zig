const std = @import("std");
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

    /// Discord API URL
    api_url: []const u8,
};

const separator = "__";
const prefix = "EDB" ++ separator;

pub fn loadConfig(
    environ_map: *std.process.Environ.Map,
) !Config {
    var config: Config = @import("config_default.zon");

    const server = prefix ++ "SERVER" ++ separator;

    if (environ_map.get(server ++ "PORT")) |port| {
        config.server.port = try std.fmt.parseInt(u16, port, 10);
    }

    const log = prefix ++ "LOG" ++ separator;

    if (environ_map.get(log ++ "JSON_FORMAT")) |json_format| {
        config.log.json_format =
            if (std.mem.eql(u8, json_format, "true"))
                true
            else
                false;
    }

    if (environ_map.get(log ++ "LEVEL")) |level| {
        config.log.level = std.meta.stringToEnum(logz.Level, level) orelse {
            return error.InvalidLogLevel;
        };
    }

    const discord = prefix ++ "DISCORD" ++ separator;

    if (environ_map.get(discord ++ "APP_ID")) |app_id| {
        config.discord.app_id = app_id;
    }

    if (environ_map.get(discord ++ "PUBLIC_KEY")) |public_key| {
        config.discord.public_key = public_key;
    }

    if (environ_map.get(discord ++ "TOKEN")) |token| {
        config.discord.token = token;
    }

    if (environ_map.get(discord ++ "API_URL")) |api_url| {
        config.discord.api_url = api_url;
    }

    return config;
}
