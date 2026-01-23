const std = @import("std");
const kiwiwi = @import("kiwiwi");

// @dev catch all elevated errors and terminate the app if exists.
pub fn main() !void {
    kiwiwi.Run() catch |err| {
        const red = "\x1b[31m";
        const reset = "\x1b[0m";
        std.debug.print("\n{s}[X] {s}{s} Kiwiwi crashed, terminating app.\n", .{ red, @errorName(err), reset });
        std.process.exit(1);
    };
}
