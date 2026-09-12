const std = @import("std");
const httpz = @import("httpz");
const RequestContext = @import("server/state.zig").RequestContext;
const log = @import("server/logger.zig");
const documentations = @import("doc.zig").documentations;

pub fn health(_: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .status = "UP" }, .{});
}

pub fn interactions(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    const signature = req.header("x-signature-ed25519") orelse {
        log.warn("Missing 'X-Signature-Ed25519' header", .{});
        res.status = 401;
        return;
    };

    const timestamp = req.header("x-signature-timestamp") orelse {
        log.warn("Missing 'X-Signature-Timestamp' header", .{});
        res.status = 401;
        return;
    };

    const body = req.body() orelse {
        log.warn("Missing body", .{});
        res.status = 401;
        return;
    };

    ctx.app.auth_service.verifyDiscordRequest(
        signature,
        timestamp,
        body,
    ) catch |err| {
        log.warn("Auth failed: {}", .{err});
        res.status = 401;
        return;
    };

    const interaction = try std.json.parseFromSliceLeaky(
        InteractionRequest,
        req.arena,
        body,
        .{ .ignore_unknown_fields = true },
    );

    switch (interaction.type) {
        .ping => {
            try res.json(.{ .type = InteractionTypeResponse.pong }, .{});
        },
        .application_command => {
            const data = interaction.data orelse {
                log.warn("Missing data", .{});
                res.status = 400;
                return;
            };

            const command = std.meta.stringToEnum(Command, data.name) orelse {
                log.warn("Unknown command", .{});
                res.status = 400;
                return;
            };

            // Send a message into the channel where command was triggered from
            switch (command) {
                .coin => {
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
                },
                .doc => {
                    const options = data.options orelse {
                        log.warn("Missing data.options", .{});
                        res.status = 400;
                        return;
                    };

                    if (options.len == 0) {
                        log.warn("No data.options", .{});
                        res.status = 400;
                        return;
                    }

                    const option_value = options[0].value orelse {
                        log.warn("Missing data.options[0].value", .{});
                        res.status = 400;
                        return;
                    };

                    const doc_name = switch (option_value) {
                        .string => |v| v,
                        else => {
                            log.warn("Missing data.options[0].value", .{});
                            res.status = 400;
                            return;
                        },
                    };

                    const content = findDocContent(doc_name) orelse {
                        log.warn("Missing documentation '{s}'", .{doc_name});
                        res.status = 400;
                        return;
                    };

                    const interaction_response = InteractionResponse{
                        .type = InteractionTypeResponse.channel_message_with_source,
                        .data = .{
                            .flags = InteractionFlagsResponse.is_components_v2,
                            .components = &[_]MessageComponentResponse{
                                .{
                                    .type = ComponentTypeResponse.container,
                                    .components = &[_]MessageComponentResponse{
                                        .{
                                            .type = ComponentTypeResponse.text_display,
                                            .content = content,
                                        },
                                    },
                                },
                            },
                        },
                    };

                    try res.json(interaction_response, .{});
                },
            }
        },
        else => {
            log.warn("Unknown interaction", .{});
            res.status = 400;
        },
    }
}

fn findDocContent(doc_name: []const u8) ?[]const u8 {
    for (documentations) |documentation| {
        if (std.mem.eql(u8, documentation.name, doc_name)) {
            return documentation.content;
        }
    }
    return null;
}

/// 1-32 characters
pub const Command = enum {
    coin,
    doc,
};

// https://docs.discord.com/developers/interactions/receiving-and-responding#interaction-object
const InteractionRequest = struct {
    type: InteractionTypeRequest,
    data: ?ApplicationCommandDataRequest = null,
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
    options: ?[]const ApplicationCommandDataOptionRequest = null,
};

const ApplicationCommandDataOptionRequest = struct {
    value: ?ApplicationCommandDataOptionValueRequest,
};

const ApplicationCommandDataOptionValueRequest = union(enum) {
    string: []const u8,
    integer: i64,
    double: f64,
    boolean: bool,

    pub fn jsonParse(
        allocator: std.mem.Allocator,
        source: anytype,
        options: std.json.ParseOptions,
    ) !ApplicationCommandDataOptionValueRequest {
        const json = try std.json.innerParse(std.json.Value, allocator, source, options);

        return switch (json) {
            .string => |v| .{ .string = v },
            .integer => |v| .{ .integer = v },
            .float => |v| .{ .double = v },
            .bool => |v| .{ .boolean = v },
            else => error.UnexpectedToken,
        };
    }
};

// https://docs.discord.com/developers/interactions/receiving-and-responding#interaction-response-object
const InteractionResponse = struct {
    type: InteractionTypeResponse,
    data: ?ApplicationCommandDataResponse = null,
};

const ApplicationCommandDataResponse = struct {
    flags: ?u32 = null,
    components: ?[]const MessageComponentResponse = null,
};

const MessageComponentResponse = struct {
    type: ComponentTypeResponse,
    content: ?[]const u8 = null,
    components: ?[]const MessageComponentResponse = null,
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

const ComponentTypeResponse = enum(u5) {
    /// Container to display a row of interactive components
    action_row = 1,
    /// Button object
    button = 2,
    /// Select menu for picking from defined text options
    string_select = 3,
    /// Text input object
    text_input = 4,
    /// Select menu for users
    user_select = 5,
    /// Select menu for roles
    role_select = 6,
    /// Select menu for mentionables (users and roles)
    mentionable_select = 7,
    /// Select menu for channels
    channel_select = 8,
    /// Container to display text alongside an accessory component
    section = 9,
    /// Markdown text
    text_display = 10,
    /// Small image that can be used as an accessory
    thumbnail = 11,
    /// Display images and other media
    media_gallery = 12,
    /// Displays an attached file
    file = 13,
    /// Component to add vertical padding between other components
    separator = 14,
    /// Container that visually groups a set of components
    container = 17,
    /// Container associating a label and description with a component
    label = 18,
    /// Component for uploading files
    file_upload = 19,
    /// Single-choice set of options
    radio_group = 21,
    /// Multi-selectable group of checkboxes
    checkbox_group = 22,
    /// Single checkbox for yes/no choice
    checkbox = 23,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.write(@intFromEnum(self.*));
    }
};
