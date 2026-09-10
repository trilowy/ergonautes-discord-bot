const std = @import("std");
const httpz = @import("httpz");
const RequestContext = @import("server/state.zig").RequestContext;

pub fn health(_: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .status = "UP" }, .{});
}

pub fn interactions(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    const signature = req.headers.get("X-Signature-Ed25519") orelse {
        res.status = 401;
        return;
    };

    const timestamp = req.headers.get("X-Signature-Timestamp") orelse {
        res.status = 401;
        return;
    };

    const body = req.body() orelse {
        res.status = 401;
        return;
    };

    ctx.app.auth_service.verifyDiscordRequest(
        signature,
        timestamp,
        body,
    ) catch {
        res.status = 401;
        return;
    };

    const interaction = try req.json(InteractionRequest) orelse return;

    switch (interaction.type) {
        .ping => {
            try res.json(.{ .type = InteractionTypeResponse.pong }, .{});
        },
        .application_command => {
            const data = interaction.data orelse {
                res.status = 400;
                return;
            };

            if (std.mem.eql(u8, data.name, "test")) {
                // Send a message into the channel where command was triggered from
                const interaction_response = InteractionResponse{
                    .type = InteractionTypeResponse.channel_message_with_source,
                    .data = .{
                        .flags = InteractionFlagsResponse.is_components_v2,
                        .components = &[_]MessageComponentResponse{
                            .{
                                .type = ComponentTypeResponse.text_display,
                                .content = "Coin ! 🦆",
                            },
                        },
                    },
                };

                try res.json(interaction_response, .{});
            } else {
                // Unknown command
                res.status = 400;
            }
        },
        else => {
            res.status = 400;
        },
    }
}

// https://docs.discord.com/developers/interactions/receiving-and-responding#interaction-object
const InteractionRequest = struct {
    type: InteractionTypeRequest,
    data: ?ApplicationCommandDataRequest,
};

const InteractionTypeRequest = enum(u3) {
    ping = 1,
    application_command = 2,
    message_component = 3,
    application_command_autocomplete = 4,
    modal_submit = 5,
};

const ApplicationCommandDataRequest = struct {
    name: []const u8,
};

// https://docs.discord.com/developers/interactions/receiving-and-responding#interaction-response-object
const InteractionResponse = struct {
    type: InteractionTypeResponse,
    data: ?ApplicationCommandDataResponse,
};

const ApplicationCommandDataResponse = struct {
    flags: ?u32,
    components: ?[]const MessageComponentResponse,
};

const MessageComponentResponse = struct {
    type: ComponentTypeResponse,
    content: []const u8,
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

const InteractionFlagsResponse = struct {
    pub const suppress_embeds: u32 = 1 << 2;
    pub const ephemeral: u32 = 1 << 6;
    pub const suppress_notifications: u32 = 1 << 12;
    pub const is_voice_message: u32 = 1 << 13;
    pub const is_components_v2: u32 = 1 << 15;
};

const ComponentTypeResponse = enum(u4) {
    text_display = 10,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};
