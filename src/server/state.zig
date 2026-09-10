const std = @import("std");
const httpz = @import("httpz");
const log = @import("../server/logger.zig");
const DiscordConfig = @import("../server/config.zig").DiscordConfig;
const AuthService = @import("../AuthService.zig");

pub const App = struct {
    io: std.Io,
    auth_service: AuthService,

    pub fn dispatch(self: *App, action: httpz.Action(*RequestContext), req: *httpz.Request, res: *httpz.Response) !void {
        var start = std.Io.Timestamp.now(self.io, .awake);

        var ctx = RequestContext{
            .app = self,
        };

        try action(&ctx, req, res);

        const elapsed_ms = start.untilNow(self.io, .awake).toMilliseconds();

        log.debug("{} {s} {d}ms", .{ req.method, req.url.path, elapsed_ms });
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
