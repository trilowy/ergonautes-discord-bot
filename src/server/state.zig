const std = @import("std");
const httpz = @import("httpz");
const log = @import("../server/logger.zig");
const DiscordConfig = @import("../server/config.zig").DiscordConfig;

pub const App = struct {
    discord_config: DiscordConfig,

    pub fn dispatch(self: *App, action: httpz.Action(*RequestContext), req: *httpz.Request, res: *httpz.Response) !void {
        var timer = try std.time.Timer.start();

        var ctx = RequestContext{
            .app = self,
        };

        try action(&ctx, req, res);

        const elapsed = timer.lap() / 1_000_000; // ns -> ms
        log.debug("{} {s} {d}ms", .{ req.method, req.url.path, elapsed });
    }

    pub fn notFound(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
        log.info("404 {} {s}", .{ req.method, req.url.path });
        res.status = 404;
    }

    pub fn uncaughtError(_: *App, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
        log.err("500 {} {s} {}", .{ req.method, req.url.path, err });
        res.status = 500;
    }
};

pub const RequestContext = struct {
    app: *App,
};
