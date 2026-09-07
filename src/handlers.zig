const httpz = @import("httpz");
const RequestContext = @import("server/state.zig").RequestContext;

pub fn health(_: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .status = "UP" }, .{});
}

pub fn interactions(_: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .hello = "world" }, .{});
}
