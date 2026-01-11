const std = @import("std");
const kiwiwi = @import("kiwiwi");

// @dev catch all elevated errors and terminate the app if exists.
pub fn main() !void {
    std.debug.print("project {s} with version {d}\n", .{ "kiwiwi", 0.1 });

    kiwiwi.Run() catch |err| {
        std.debug.print("Failed to run Kiwiwi application with reason: {s}, terminating app.\n", .{@errorName(err)});
        std.process.exit(1);
    };
}
