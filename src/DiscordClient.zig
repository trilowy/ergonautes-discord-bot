const std = @import("std");
const log = @import("server/logger.zig");
const DiscordConfig = @import("server/config.zig").DiscordConfig;
const Headers = std.http.Client.Request.Headers;
const Command = @import("handlers.zig").Command;
const documentations = @import("doc").documentations;

const Self = @This();

arena: std.heap.ArenaAllocator,
http_client: std.http.Client,
authorization_header: Headers.Value,
command_url: []const u8,

const discord_user_agent = Headers.Value{ .override = "DiscordBot (https://ziglang.org, 0.16.0)" };
const json_content_type = Headers.Value{ .override = "application/json" };

// TODO: 25 might not be enough, search other completion command
const choices = blk: {
    var doc_choices: [documentations.len]CommandOptionChoiceRequest = undefined;

    for (documentations, 0..) |documentation, i| {
        doc_choices[i] = .{
            .name = documentation.name,
            .value = .{ .string = documentation.name },
        };
    }

    break :blk doc_choices;
};

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
            .type = .chat_input,
            .name = .coin,
            .description = "Discute avec QuackBot",
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
        .{
            .type = .chat_input,
            .name = .doc,
            .description = "Demande de l’aide à QuackBot à propos des claviers",
            .options = &[_]CommandOptionRequest{
                .{
                    .type = .string,
                    .name = "nom",
                    .description = "Choisis la documentation que tu veux afficher dans le canal",
                    .required = true,
                    .choices = &choices,
                },
            },
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
            .user_agent = discord_user_agent,
            .authorization = self.authorization_header,
            .content_type = json_content_type,
        },
    });

    log.debug(
        "Response status: {d}, payload: {s}",
        .{ response.status, response_body.written() },
    );
}

/// https://docs.discord.com/developers/interactions/application-commands#application-command-object
const CommandRequest = struct {
    type: CommandType,
    name: Command,
    /// 1-100 character
    description: []const u8,
    options: ?[]const CommandOptionRequest = null,
    integration_types: ?[]const ApplicationIntegrationType = null,
    contexts: ?[]const InteractionContextType = null,
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

const CommandOptionRequest = struct {
    type: CommandOptionType,
    /// 1-32 character
    name: []const u8,
    /// 1-100 character
    description: []const u8,
    required: ?bool = null,
    /// Max 25
    choices: ?[]const CommandOptionChoiceRequest = null,
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

const CommandOptionType = enum(u4) {
    sub_command = 1,
    sub_command_group = 2,
    string = 3,
    integer = 4,
    boolean = 5,
    user = 6,
    channel = 7,
    role = 8,
    mentionable = 9,
    number = 10,
    attachment = 11,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};

const CommandOptionChoiceRequest = struct {
    /// 1-100 character
    name: []const u8,
    value: CommandOptionChoiceValue,
};

const CommandOptionChoiceValue = union(enum) {
    /// Max 100 characters
    string: []const u8,
    /// Any integer between -2^53+1 and 2^53-1
    int: i64,
    /// Any double between -2^53 and 2^53
    double: f64,

    /// Print only value, not tag name
    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        switch (self.*) {
            inline else => |value| try jw.write(value),
        }
    }
};
