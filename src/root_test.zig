const std = @import("std");
const kiwiwi = @import("root.zig");
const expect = std.testing.expect;

const MakeError = std.fs.Dir.MakeError;
const SkipError = error.SkipZigTest;

fn Skip() !void {
    const shouldSkip = true;
    if (shouldSkip) return SkipError;
}

// @dev zed editor might not immediately refresh append file contents.
test "Should create a directory and a file" {
    try Skip();

    const dirName = "testdummy";
    std.fs.cwd().makeDir(dirName) catch |err| switch (err) {
        MakeError.PathAlreadyExists => {
            std.debug.print("Directory already exists, skipping.\n", .{});
        },
        else => return err,
    };

    var directory = try std.fs.cwd().openDir(dirName, .{ .access_sub_paths = true, .iterate = true });
    defer directory.close();

    // const isNewFile = false;
    var file = directory.openFile("controller.go", .{ .mode = .read_write }) catch |err| switch (err) {
        // std.fs.File.OpenError.FileNotFound => { // @dev either error or File
        //     isNewFile = true;
        //     // break :blk try directory.createFile("controller.go", .{ .lock = .shared, .read = true, .truncate = true });
        //     const newFile = try directory.createFile("controller.go", .{ .lock = .shared, .read = true, .truncate = true });
        //     return newFile;
        // },
        std.fs.File.OpenError.FileNotFound => try directory.createFile("controller.go", .{ .lock = .shared, .read = true, .truncate = true }),
        else => return err,
    };
    defer file.close();

    const stat = try file.stat();
    const isEmpty = stat.size == 0;

    try file.seekFromEnd(0);
    if (isEmpty) {
        std.debug.print("dealing with a new file.\n", .{});
        _ = try file.writeAll("package controller \n\nfunc myController() error { return nil }\n\n");
    } else {
        std.debug.print("dealing with an existing file.\n", .{});
        _ = try file.writeAll("func myController() error { return nil }\n\n");
    }
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
    const moduleName = "github.com/kiwiwi";

    std.debug.print("template: {s}\n", .{template});
    std.debug.print("template type: {any}\n", .{templateType});
    std.debug.print("template type name: {s}\n", .{templateTypeName});

    const controllerName = "Health";
    const controllerTemplate = try std.fmt.allocPrint(allocator, template, .{ controllerName, "GET", "get", moduleName });
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
    try Skip();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const message = "HELLO";
    const copied = try allocator.dupe(u8, message);

    const shouldBeLowerCase = std.ascii.toLower(copied[0]);
    std.debug.print("{c}\n", .{shouldBeLowerCase});
    defer allocator.free(copied);
}

test "Should print a generated ascii art" {
    try Skip();

    const kiwi =
        \\                                       .-+*##*=:.   KIWIWI~!!
        \\                                    .-#*+-----=+*#+.  /
        \\                                    +#=-----------=#%-
        \\                                   *#=+#-------------+#%*:.
        \\                                .=##*+*%=-*+------------=#*.
        \\                              .*#-::::+%------------------#+
        \\                              **=#%%%=--------------------+#
        \\                              .::. .@=--------------------*+
        \\                                    -%=------------------+#.
        \\                                     :#*----------------*#:
        \\                                       .*#*++==---==+*#*:
        \\                                          .::--=%#=-**.
        \\                                                :#: .*-
        \\                                                :*-  -#.
        \\                                               .=:. -*-.
    ;

    std.debug.print("{s}\n", .{kiwi});
}

test "Should concat strings in comptime" {
    try Skip();

    const str1 = "Hello";
    const str2 = "World";

    // @dev use `++` operator for comptime, use allocator for runtime.
    const result = str1 ++ " " ++ str2;
    std.debug.print("{s}\n", .{result});
}

test "Should find a go.mod file" {
    try Skip();
    // const parent = std.fs.path.dirname(path) orelse "ww";
    // 1. set a start, end directory to search
    // 2. check current directory for go.mod
    // 3. if not found, move to parent directory
    // 4. repeat until start directory is reached

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const base_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();

    var current_path = try std.fs.cwd().realpathAlloc(arena.allocator(), ".");
    var directory = try std.fs.openDirAbsolute(current_path, .{});
    defer directory.close();

    while (true) {
        directory.access("go.mod.txt", .{ .mode = .read_only }) catch |err| switch (err) {
            error.FileNotFound => {
                std.debug.print("Go.mod not found in: {s}\n", .{current_path});
                const parent = std.fs.path.dirname(current_path) orelse {
                    return error.EndOfDirectory;
                };
                directory = try directory.openDir(parent, .{});
                current_path = try arena.allocator().dupe(u8, parent);
                continue;
            },
            else => return err,
        };

        std.debug.print("Found go.mod in: {s}\n", .{current_path});
        break;
    }
}

test "Should parse a module name from go.mod" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const base_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();

    const current_path = try std.fs.cwd().realpathAlloc(arena.allocator(), ".");
    var directory = try std.fs.openDirAbsolute(current_path, .{});
    defer directory.close();

    std.debug.print("current dir: {s}\n", .{current_path});
    const sub_path = "testdummy/go.mod";
    var file = try directory.openFile(sub_path, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    std.debug.print("size: {any}\n", .{stat.size});

    const buffer = try arena.allocator().alloc(u8, stat.size);
    const content = try directory.readFile(sub_path, buffer);

    std.debug.print("content: {s}\n", .{content});

    var iterator = std.mem.tokenizeAny(u8, content, " \n\r\t");
    var moduleName: []const u8 = "github.com/kiwiwi";

    while (iterator.next()) |token| {
        std.debug.print("token: {s}\n", .{token});

        if (std.mem.eql(u8, token, "module")) {
            moduleName = iterator.next() orelse {
                return error.InvalidGoMod;
            };
            break;
        }
    }

    std.debug.print("module name: {s}\n", .{moduleName});
}
