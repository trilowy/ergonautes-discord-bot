const std = @import("std");
const DiscordClient = @import("DiscordClient.zig");

const Self = @This();

arena: *std.heap.ArenaAllocator,
discord_client: *DiscordClient,
contrib_role_name: []const u8,
guild_id_to_contrib_role_id: std.StringHashMapUnmanaged([]const u8) = .empty,

pub fn getContribRoleId(
    self: *const Self,
    guild_id: []const u8,
) ![]const u8 {
    return self.guild_id_to_contrib_role_id.get(guild_id) orelse {
        // TODO: call API and store it and return it, if not found on API => error
        // TODO: own the map values to avoid deallocation after the end of API call
        return error.DiscordApiNoContribRoleId;
    };
}
