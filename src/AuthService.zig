const std = @import("std");
const Ed25519 = std.crypto.sign.Ed25519;
const DiscordConfig = @import("server/config.zig").DiscordConfig;

const Self = @This();

public_key: Ed25519.PublicKey,

pub fn init(discord: DiscordConfig) !Self {
    // Discord uses hex-encoded Ed25519 values (1 byte = 2 hex char)
    if (discord.public_key.len != Ed25519.PublicKey.encoded_length * 2) {
        return error.PublicKeySize;
    }

    var public_key_bytes: [Ed25519.PublicKey.encoded_length]u8 = undefined;

    _ = try std.fmt.hexToBytes(&public_key_bytes, discord.public_key);

    const public_key = try Ed25519.PublicKey.fromBytes(public_key_bytes);

    return Self{
        .public_key = public_key,
    };
}

pub fn verifyDiscordRequest(
    self: *const Self,
    signature_hex: []const u8,
    timestamp: []const u8,
    raw_body: []const u8,
) !void {
    // Discord uses hex-encoded Ed25519 values (1 byte = 2 hex char)
    if (signature_hex.len != Ed25519.Signature.encoded_length * 2) {
        return error.SignatureSize;
    }

    var signature_bytes: [Ed25519.Signature.encoded_length]u8 = undefined;

    _ = try std.fmt.hexToBytes(&signature_bytes, signature_hex);

    const signature = Ed25519.Signature.fromBytes(signature_bytes);

    // Check signature on timestamp + raw HTTP body
    var verifier = try signature.verifier(self.public_key);
    verifier.update(timestamp);
    verifier.update(raw_body);
    try verifier.verify();
}
