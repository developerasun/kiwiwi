//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const expect = std.testing.expect;

const MakeError = std.fs.Dir.MakeError;

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

test "Should create a directory and a file" {
    const dirName = "controller";
    std.fs.cwd().makeDir(dirName) catch |err| switch (err) {
        MakeError.PathAlreadyExists => {
            std.debug.print("Directory already exists, skipping.\n", .{});
        },
        else => return err,
    };

    // .{ }: anonymous struct literal
    const openOptions: std.fs.Dir.OpenOptions = .{ .iterate = true };
    const fileOptions: std.fs.File.CreateFlags = .{
        .read = true,
        .truncate = true,
    };
    const directory = try std.fs.cwd().openDir(dirName, openOptions);
    const file = directory.createFile("controller.go", fileOptions) catch |err| {
        std.debug.print("Error creating file: {any}\n", .{err});
        return err;
    };
    defer file.close();

    // TODO keep original file content, append new content to the file
    try directory.writeFile(.{
        .data = "package controller \n\n func myController() error { return nil }",
        .sub_path = "controller.go", // @dev add comma at the end to change line.
    });
    std.debug.print("file create done.\n", .{});
}
