//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const tests = @import("root.test.zig");

const MakeError = std.fs.Dir.MakeError;
const SkipError = error.SkipZigTest;

pub fn metadata() void {
    const p = project();
    const v = version();
    std.debug.print("project {s} with version {d}\n", .{ p, v });
}

fn project() []const u8 {
    return "kiwiwi";
}

fn version() f32 {
    return 0.1;
}

// @dev split test suites from implementation
test "Should reference all test cases" {
    std.testing.refAllDeclsRecursive(@This());
}
