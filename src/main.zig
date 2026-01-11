const std = @import("std");
const kiwiwi = @import("kiwiwi");

// @dev catch all elevated errors and terminate the app if exists.
pub fn main() !void {
    kiwiwi.Run() catch |err| {
        std.debug.print("Failed to run with reason: {s}, terminating app.\n", .{@errorName(err)});
        std.process.exit(1);
    };
}
