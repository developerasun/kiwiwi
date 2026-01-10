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

pub fn ParseArgument() ![]const u8 {
    var args = std.process.args();
    _ = args.next().?; // @dev ignore program name

    const firstArg = args.next();

    if (firstArg) |arg| {
        std.debug.print("firstArg: {s}\n", .{arg});
        return arg;
    } else {
        return error.MissingArgument;
    }
}

pub fn Generate(controllerName: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit(); // @dev ensure no memory leaks
    const allocator = gpa.allocator();

    const tmpl = try buildControllerTemplate(allocator, controllerName);
    std.debug.print("template: {s}\n", .{tmpl});

    defer allocator.free(tmpl);
}

fn buildControllerTemplate(allocator: std.mem.Allocator, controllerName: []const u8) ![]const u8 {
    const template = @embedFile("./templates/controller.kiwiwi");
    const controllerTemplate = try std.fmt.allocPrint(allocator, template, .{controllerName});

    return controllerTemplate;
}

// @dev split test suites from implementation
test "Should reference all test cases" {
    std.testing.refAllDeclsRecursive(@This());
}
