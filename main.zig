const std = @import("std");

pub fn main() !void {
    return build();
}

fn project() []const u8 {
    return "kiwiwi";
}

fn version() f32 {
    return 0.1;
}

fn build() void {
    const p = project();
    const v = version();
    std.debug.print("project {s} with version {d}\n", .{ p, v });
}
