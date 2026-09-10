const httpz = @import("httpz");
const RequestContext = @import("server/state.zig").RequestContext;

pub fn health(_: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .status = "UP" }, .{});
}

pub fn interactions(_: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    const interaction = try req.json(InteractionRequest) orelse return; // TODO: error?

    switch (interaction.type) {
        .ping => {
            try res.json(.{ .type = InteractionTypeResponse.pong }, .{});
        },
        else => {
            // TODO: unsupported
            try res.json(.{ .hello = "world" }, .{});
        },
    }
}

const InteractionRequest = struct {
    type: InteractionType,
};

const InteractionType = enum(u3) {
    ping = 1,
    application_command = 2,
    message_component = 3,
    application_command_autocomplete = 4,
    modal_submit = 5,
};

const InteractionTypeResponse = enum(u4) {
    /// ACK a Ping
    pong = 1,
    /// Respond to an interaction with a message
    channel_message_with_source = 4,
    /// ACK an interaction and edit a response later, the user sees a loading state
    deferred_channel_message_with_source = 5,
    /// For components, ACK an interaction and edit the original message later; the user does not see a loading state
    deferred_update_message = 6,
    /// For components, edit the message the component was attached to
    update_message = 7,
    /// Respond to an autocomplete interaction with suggested choices
    application_command_autocomplete_result = 8,
    /// Respond to an interaction with a popup modal
    modal = 9,
    /// Launch the Activity associated with the app. Only available for apps with Activities enabled
    launch_activity = 12,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};
