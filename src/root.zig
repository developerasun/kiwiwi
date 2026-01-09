//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const expect = std.testing.expect;

fn project() []const u8 {
    return "kiwiwi";
}

fn version() f32 {
    return 0.1;
}

pub fn metadata() void {
    const p = project();
    const v = version();
    std.debug.print("project {s} with version {d}\n", .{ p, v });
}

test "project" {
    const p = project();
    try std.testing.expectEqual(p, "kiwiwi");

    const v = version();
    try std.testing.expectEqual(v, 0.1);
}
