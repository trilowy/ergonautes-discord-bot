const curl = @import("curl");
const std = @import("std");
const log = @import("server/logger.zig");
const DiscordConfig = @import("server/config.zig").DiscordConfig;

const Self = @This();

curl_client: curl.Easy,
authorization_header: [:0]const u8,
command_url: [:0]const u8,

pub fn init(
    allocator: std.mem.Allocator,
    discord: DiscordConfig,
) !Self {
    const authorization_header = try std.fmt.allocPrintSentinel(
        allocator,
        "Authorization: Bot {s}",
        .{discord.token},
        0,
    );
    errdefer allocator.free(authorization_header);

    const command_url = try std.fmt.allocPrintSentinel(
        allocator,
        "{s}/applications/{s}/commands",
        .{ discord.api_url, discord.app_id },
        0,
    );
    errdefer allocator.free(command_url);

    const ca_bundle = try curl.allocCABundle(allocator);
    errdefer ca_bundle.deinit();

    var curl_client = try curl.Easy.init(.{
        .ca_bundle = ca_bundle,
    });
    errdefer curl_client.deinit();

    return Self{
        .curl_client = curl_client,
        .authorization_header = authorization_header,
        .command_url = command_url,
    };
}

pub fn deinit(
    self: *Self,
    allocator: std.mem.Allocator,
) void {
    self.curl_client.deinit();
    self.curl_client.ca_bundle.?.deinit();
    allocator.free(self.command_url);
    allocator.free(self.authorization_header);
}

pub fn registerCommandsToDiscord(
    self: *Self,
    allocator: std.mem.Allocator,
) !void {
    // TODO: register Discord commands at server startup
    var headers: curl.Easy.Headers = .{};
    defer headers.deinit();
    try headers.add(self.authorization_header);

    try self.curl_client.setUrl(self.command_url);
    try self.curl_client.setHeaders(headers);
    try self.curl_client.setMethod(.GET);

    var writer = std.Io.Writer.Allocating.init(allocator);
    defer writer.deinit();
    try self.curl_client.setWriter(&writer.writer);

    const resp = try self.curl_client.perform();
    log.info(
        "Status code: {d} Body: {s}",
        .{ resp.status_code, writer.writer.buffered() },
    );
}
