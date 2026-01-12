const std = @import("std");
const kiwiwi = @import("root.zig");
const expect = std.testing.expect;

const MakeError = std.fs.Dir.MakeError;
const SkipError = error.SkipZigTest;

fn Skip() !void {
    const shouldSkip = true;
    if (shouldSkip) return SkipError;
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
    try Skip();

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

test "Should print a templated controller" {
    try Skip();

    const allocator = std.testing.allocator;
    const template = @embedFile("./templates/controller.kiwiwi");
    const templateType = @TypeOf(template);
    const templateTypeName = @typeName(templateType);

    std.debug.print("template: {s}\n", .{template});
    std.debug.print("template type: {any}\n", .{templateType});
    std.debug.print("template type name: {s}\n", .{templateTypeName});

    const controllerName = "Health";
    const controllerTemplate = try std.fmt.allocPrint(allocator, template, .{ controllerName, "GET", "get" });
    defer allocator.free(controllerTemplate);

    std.debug.print("full template: {s}\n", .{controllerTemplate});
}

test "Should allocate a memory for an array list" {
    try Skip();
    // @dev use stack memory for fixed size array. no heap allocator should be used.
    var buffer: [5]u8 = .{ 1, 2, 3, 4, 5 };
    var bb = std.ArrayList(u8).initBuffer(&buffer); // relatively faster

    bb.items.len = 5;
    std.debug.print("bb [0]: {d}\n", .{bb.items[0]});

    // @dev use heap memory for dynamic size arrary. gpa must be var as it is mutable
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty; // relatively slower
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    std.debug.print("last element: {d}", .{list.getLast()});
    try expect(list.getLast() == 10);
}

test "Should extract command lin args" {
    try Skip();

    var args = std.process.args();
    // @dev 0th element of cli args is program name, which absolutely exist.
    const programName = args.next().?;
    std.debug.print("programName: {s}\n", .{programName});

    // @dev 1st cli args may not exist.
    // in test suite, it always exists.: ./.zig-cache/o/9b8d31f77ae45d2e0b8a56b8f8845110/test --cache-dir=./.zig-cache --seed=0x74fe2bff --listen=-
    const firstArg = args.next(); // --cache-dir=./.zig-cache

    // @dev extract the args with payload capture
    if (firstArg) |arg| {
        std.debug.print("firstArg: {s}\n", .{arg});
        try std.testing.expectEqualStrings("--cache-dir=./.zig-cache", arg);
    } else {
        @panic("firstArg is null");
    }
}

test "Should convert to upper case string" {
    try Skip();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // multiple alloc, free once
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const methodGet = "get";
    const methodPost = "post";

    const outputGet = try arena.allocator().alloc(u8, methodGet.len);
    const upperGet = std.ascii.upperString(outputGet, methodGet);
    try expect(std.mem.eql(u8, upperGet, "GET"));

    const outputPost = try arena.allocator().alloc(u8, methodPost.len);
    const upperPost = std.ascii.upperString(outputPost, methodPost);
    try expect(std.mem.eql(u8, upperPost, "POST"));

    std.debug.print("upperGet: {s}\n", .{upperGet});
    std.debug.print("upperPost: {s}\n", .{upperPost});
}

test "Should safely mutate a char" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const message = "HELLO";
    const copied = try allocator.dupe(u8, message);

    const shouldBeLowerCase = std.ascii.toLower(copied[0]);
    std.debug.print("{c}\n", .{shouldBeLowerCase});
    defer allocator.free(copied);
}
