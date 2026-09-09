const std = @import("std");
const log = @import("server/logger.zig");
const DiscordConfig = @import("server/config.zig").DiscordConfig;
const Headers = std.http.Client.Request.Headers;

const Self = @This();

arena: std.heap.ArenaAllocator,
http_client: std.http.Client,
authorization_header: Headers.Value,
command_url: []const u8,

pub fn init(
    io: std.Io,
    allocator: std.mem.Allocator,
    discord: DiscordConfig,
) !Self {
    var arena_allocator = std.heap.ArenaAllocator.init(allocator);
    errdefer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    var http_client: std.http.Client = .{ .allocator = allocator, .io = io };
    errdefer http_client.deinit();

    const authorization_header_string = try std.fmt.allocPrint(
        arena,
        "Bot {s}",
        .{discord.token},
    );
    const authorization_header = Headers.Value{ .override = authorization_header_string };

    const command_url = try std.fmt.allocPrint(
        arena,
        "{s}/applications/{s}/commands",
        .{ discord.api_url, discord.app_id },
    );

    return Self{
        .arena = arena_allocator,
        .http_client = http_client,
        .authorization_header = authorization_header,
        .command_url = command_url,
    };
}

pub fn deinit(self: *Self) void {
    self.http_client.deinit();
    self.arena.deinit();
}

pub fn registerCommandsToDiscord(
    self: *Self,
    allocator: std.mem.Allocator,
) !void {
    log.info("Registering commands to Discord", .{});

    const request = [_]CommandRequest{
        .{
            .name = "test",
            .description = "Basic command",
            .type = .chat_input,
            .integration_types = &[_]ApplicationIntegrationType{
                .guild_install,
                .user_install,
            },
            .contexts = &[_]InteractionContextType{
                .guild,
                .bot_dm,
                .private_channel,
            },
        },
    };

    const payload = try std.json.Stringify.valueAlloc(allocator, request, .{});
    defer allocator.free(payload);

    log.debug("Request payload: {s}", .{payload});

    var response_body: std.Io.Writer.Allocating = .init(allocator);
    defer response_body.deinit();

    const response = try self.http_client.fetch(.{
        .location = .{ .url = self.command_url },
        .method = .PUT,
        .payload = payload,
        .response_writer = &response_body.writer,
        .headers = .{
            .content_type = .{ .override = "application/json" },
            .authorization = self.authorization_header,
        },
    });

    log.debug(
        "Response status: {d}, payload: {s}",
        .{ response.status, response_body.written() },
    );
}

const CommandRequest = struct {
    name: []const u8,
    description: []const u8,
    type: ?CommandType,
    integration_types: ?[]const ApplicationIntegrationType,
    contexts: ?[]const InteractionContextType,
};

const CommandType = enum(u3) {
    /// Slash commands; a text-based command that shows up when a user types /
    chat_input = 1,
    /// A UI-based command that shows up when you right click or tap on a user
    user = 2,
    /// A UI-based command that shows up when you right click or tap on a message
    message = 3,
    /// A UI-based command that represents the primary way to invoke an app’s Activity
    primary_entry_point = 4,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};

const ApplicationIntegrationType = enum(u1) {
    /// App is installable to servers
    guild_install = 0,
    /// App is installable to users
    user_install = 1,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};

const InteractionContextType = enum(u2) {
    /// Interaction can be used within servers
    guild = 0,
    /// Interaction can be used within DMs with the app’s bot user
    bot_dm = 1,
    /// Interaction can be used within Group DMs and DMs other than the app’s bot user
    private_channel = 2,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};
