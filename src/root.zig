//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const expect = std.testing.expect;

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

fn Skip() !void {
    const shouldSkip = true;
    if (shouldSkip) return SkipError;
}

test "Should return a correct metadata" {
    const p = project();
    try std.testing.expectEqual(p, "kiwiwi");

    const v = version();
    try std.testing.expectEqual(v, 0.1);
}

test "Should create a directory and a file" {
    try Skip();

    const dirName = "templates";
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
        .data = "package controller \n\nfunc myController() error { return nil }",
        .sub_path = "controller.go", // @dev add comma at the end to change line.
    });
    std.debug.print("file create done.\n", .{});
}

test "Should format a string with data" {
    const allocator = std.testing.allocator;
    const data = std.fmt.allocPrint(allocator, "time: {d}", .{std.time.timestamp()}) catch |err| switch (err) {
        std.mem.Allocator.Error.OutOfMemory => {
            std.debug.print("alloc failed.\n", .{});
            return err;
        },
        else => return err,
    };

    std.debug.print("data: {s}\n", .{data});
    // @dev if not freed, will cause memory leak.
    // [gpa] (err): memory address 0x7f612b140000 leaked:
    defer allocator.free(data);
}

test "Should read a file in a directory" {
    try Skip();
    std.debug.print("file: {s}", .{@embedFile("./templates/controller.go.txt")});
    // std.fs.cwd().readFile("templates/controllers.go", buffer: []u8)
}
