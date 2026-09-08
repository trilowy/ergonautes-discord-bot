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
    // TODO: register Discord commands at server startup
    var response_body: std.Io.Writer.Allocating = .init(allocator);
    defer response_body.deinit();

    const response = try self.http_client.fetch(.{
        .location = .{ .url = self.command_url },
        .method = .GET,
        .response_writer = &response_body.writer,
        .headers = .{ .authorization = self.authorization_header },
    });

    log.info(
        "Status code: {d} Body: {s}",
        .{ response.status, response_body.written() },
    );
}
