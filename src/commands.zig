const curl = @import("curl");
const std = @import("std");
const log = @import("server/logger.zig");
const DiscordConfig = @import("server/config.zig").DiscordConfig;

pub fn registerToDiscord(
    allocator: std.mem.Allocator,
    curl_client: *curl.Easy,
    discord: DiscordConfig,
) !void {
    const url = try std.fmt.allocPrintSentinel(
        allocator,
        "{s}/applications/{s}/commands",
        .{ discord.api_url, discord.app_id },
        0,
    );
    defer allocator.free(url);

    const authorization_header = try std.fmt.allocPrintSentinel(
        allocator,
        "Authorization: Bot {s}",
        .{discord.token},
        0,
    );
    defer allocator.free(authorization_header);

    // TODO: register Discord commands at server startup
    const headers = blk: {
        var h: curl.Easy.Headers = .{};
        errdefer h.deinit();
        try h.add(authorization_header);
        break :blk h;
    };
    defer headers.deinit();

    try curl_client.setUrl(url);
    try curl_client.setHeaders(headers);
    try curl_client.setMethod(.GET);

    var writer = std.Io.Writer.Allocating.init(allocator);
    defer writer.deinit();
    try curl_client.setWriter(&writer.writer);

    const resp = try curl_client.perform();
    log.info(
        "Status code: {d} Body: {s}",
        .{ resp.status_code, writer.writer.buffered() },
    );
}
