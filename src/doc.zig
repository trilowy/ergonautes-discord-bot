const std = @import("std");

pub const documentations = [_]Documentation{
    documentationFile("doc/shift_culaire.md"),
};

pub const Documentation = struct {
    name: []const u8,
    content: []const u8,
};

fn documentationFile(comptime path: []const u8) Documentation {
    comptime {
        return .{
            .name = std.fs.path.stem(path),
            .content = @embedFile(path),
        };
    }
}
