//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const config = @import("config");
pub const tests = @import("root_test.zig");

const KiwiwiError = error{
    InvalidTemplate,
    InvalidCallback,
    InvalidGoMod,
    FlagNotSupported,
    FlagKeyNotGiven,
    FlagValueNotGiven,
    FlagNotEnoughArguments,
    FlagTooManyArguments,
    HttpMethodNotSupported,
    UndefinedBehavior,
    EndOfDirectory,
    ReachedHomeDirectory,
    EntrypointNotFound,
};

// 1. parse cli args
// 2. match template type
// 3. generate the template
// 4. display success message
pub fn Run() !void {
    const parsed = try TemplateGenerator.parseArgument();
    try TemplateGenerator.matchCallback(parsed.callback, parsed.value, parsed.httpMethod);

    return;
}

const Doctor = struct {
    fn inspect() !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const base_allocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(base_allocator);
        defer arena.deinit();

        const home = try std.process.getEnvVarOwned(arena.allocator(), "HOME");
        var current_path = try std.fs.cwd().realpathAlloc(arena.allocator(), ".");
        var directory = try std.fs.openDirAbsolute(current_path, .{});
        defer directory.close();

        while (true) {
            const home_path = try arena.allocator().dupe(u8, home);
            if (std.mem.eql(u8, home_path, current_path)) {
                std.debug.print("Reached to home directory: {s}\n", .{home_path});
                return KiwiwiError.EntrypointNotFound;
            }

            directory.access("go.mod", .{ .mode = .read_only }) catch |err| switch (err) {
                error.FileNotFound => {
                    std.debug.print("Go.mod not found in: {s}\n", .{current_path});
                    const parent = std.fs.path.dirname(current_path) orelse {
                        return KiwiwiError.EndOfDirectory;
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
};

const FlagType = struct {
    name: []const u8,
    alias: []const u8,
    description: []const u8,
};

const FlagList = struct {
    // @dev set in runtime as field member
    flags: []const FlagType,

    // @dev set in compile time in struct
    const default_flags = [_]FlagType{
        .{ .name = "cry", .alias = "-", .description = "Display symbol information" },
        .{ .name = "help", .alias = "-", .description = "Display help information" },
        .{ .name = "version", .alias = "-", .description = "Display version information" },
        .{ .name = "doctor", .alias = "-", .description = "Validate the project requirements" },
        .{ .name = "controller", .alias = "co", .description = "Generate a controller template for a http method" },
        .{ .name = "service", .alias = "s", .description = "Generate a service template" },
    };
    const default_http_methods = [_][]const u8{ "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD" };

    pub fn init() FlagList {
        return FlagList{ .flags = &default_flags };
    }

    pub fn print(self: FlagList) void {
        std.debug.print("Usage: kiwiwi [command] [alias] [description]:\n\n", .{});
        std.debug.print("Commands:\n\n", .{});

        std.debug.print("  {s:<15} | {s:<5} | {s}\n", .{ "NAME", "ALIAS", "DESCRIPTION" });
        std.debug.print("  " ++ ("-" ** 40) ++ "\n", .{});

        for (self.flags) |flag| {
            std.debug.print("  {s:<15} | {s:<5} | {s}\n", .{ flag.name, flag.alias, flag.description });
        }
        std.debug.print("\n\n", .{});
    }
};

const UserInput = struct {
    key: []const u8,
    value: []const u8,
    callback: CallbackType,
    httpMethod: ?[]const u8,
};

const CallbackType = enum {
    cry,
    help,
    version,
    doctor,
    controller,
    service,
};

const TemplateGenerator = struct {
    fn validateFlag(input: []const u8) bool {
        for (FlagList.default_flags) |flag| {
            if (std.mem.eql(u8, input, flag.name) or std.mem.eql(u8, input, flag.alias)) {
                return true;
            }
        }
        return false;
    }

    fn parseArgument() !UserInput {
        var args = std.process.args();
        _ = args.next().?; // @dev ignore program name

        const flagKey = args.next() orelse return KiwiwiError.FlagKeyNotGiven;
        const ok = validateFlag(flagKey);
        if (!ok) return KiwiwiError.FlagNotSupported;

        const flagValue = args.next() orelse {
            const fallbackValue = "";
            if (std.mem.eql(u8, flagKey, "cry")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.cry,
                    .httpMethod = null,
                };
            }

            if (std.mem.eql(u8, flagKey, "help")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.help,
                    .httpMethod = null,
                };
            }

            if (std.mem.eql(u8, flagKey, "version")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.version,
                    .httpMethod = null,
                };
            }

            if (std.mem.eql(u8, flagKey, "doctor")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.doctor,
                    .httpMethod = null,
                };
            }
            return KiwiwiError.FlagValueNotGiven;
        };

        if (std.mem.eql(u8, flagKey, "controller") or std.mem.eql(u8, flagKey, "co")) {
            try Doctor.inspect();

            const httpMethod = args.next() orelse {
                return KiwiwiError.FlagNotEnoughArguments;
            };

            return UserInput{
                .key = flagKey,
                .value = flagValue,
                .callback = CallbackType.controller,
                .httpMethod = httpMethod,
            };
        }

        if (std.mem.eql(u8, flagKey, "service") or std.mem.eql(u8, flagKey, "s")) {
            try Doctor.inspect();

            const tooManyArgs = args.next() orelse {
                return UserInput{
                    .key = flagKey,
                    .value = flagValue,
                    .callback = CallbackType.service,
                    .httpMethod = null,
                };
            };
            if (tooManyArgs.len > 0) {
                return KiwiwiError.FlagTooManyArguments;
            }
        }

        return KiwiwiError.UndefinedBehavior;
    }

    fn matchCallback(callback: CallbackType, value: []const u8, httpMethod: ?[]const u8) !void {
        switch (callback) {
            .cry => {
                printAppSymbol();
                return;
            },
            .help => {
                printAppGuide();
                return;
            },
            .version => {
                printAppVersion();
                return;
            },
            .doctor => {
                try printAppDiagnosis();
                return;
            },
            .service => {
                try generateService(value);
                return;
            },
            .controller => {
                // @dev httpMethod is guaranteed to be non-null in `parseArgument`.
                const method = httpMethod orelse {
                    unreachable;
                };
                try generateController(value, method);
                return;
            },
        }

        return KiwiwiError.InvalidCallback;
    }

    fn printAppGuide() void {
        FlagList.init().print();
    }

    fn printAppVersion() void {
        std.debug.print("Kiwiwi version {s}\n", .{config.version});
    }

    fn printAppSymbol() void {
        std.debug.print("\n{s}\n\n", .{config.symbol});
    }

    fn printAppDiagnosis() !void {
        try Doctor.inspect();

        const green = "\x1b[32m";
        const orange = "\x1b[38;5;208m";
        const reset = "\x1b[0m";
        std.debug.print("\n{s}[V]{s} Safe to proceed to use {s}Kiwiwi{s}.\n", .{ green, reset, orange, reset });
    }

    fn generateController(controllerName: []const u8, httpMethod: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const baseAllocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(baseAllocator);
        defer arena.deinit();

        // consturctor name
        const firstArg = try arena.allocator().dupe(u8, controllerName);
        firstArg[0] = std.ascii.toUpper(firstArg[0]);

        // flag check and gin group
        const bufferMethod = try arena.allocator().alloc(u8, httpMethod.len);
        const secondArgAsMethodCapitalized = std.ascii.upperString(bufferMethod, httpMethod);

        // private struct as constructor return type
        const thirdArg = try arena.allocator().dupe(u8, controllerName);
        thirdArg[0] = std.ascii.toLower(thirdArg[0]);

        // parse go module name for service path
        const current_path = try std.fs.cwd().realpathAlloc(arena.allocator(), ".");
        var directory = try std.fs.openDirAbsolute(current_path, .{});
        defer directory.close();

        const sub_path = "go.mod";
        var file = try directory.openFile(sub_path, .{ .mode = .read_only });
        defer file.close();

        const stat = try file.stat();
        const buffer = try arena.allocator().alloc(u8, stat.size);
        const content = try directory.readFile(sub_path, buffer);

        var iterator = std.mem.tokenizeAny(u8, content, " \n\r\t");
        var fourthArg: []const u8 = "github.com/kiwiwi";

        while (iterator.next()) |token| {
            if (std.mem.eql(u8, token, "module")) {
                fourthArg = iterator.next() orelse {
                    return KiwiwiError.InvalidGoMod;
                };
                break;
            }
        }
        const appendNameArg = std.crypto.random.int(u16);

        // generated template's file name
        const bufferControllerName = try arena.allocator().alloc(u8, controllerName.len);
        const fileNameAsLowercase = std.ascii.lowerString(bufferControllerName, controllerName);

        var isSupportedMethod = false;
        for (FlagList.default_http_methods) |method| {
            if (std.mem.eql(u8, method, secondArgAsMethodCapitalized)) {
                isSupportedMethod = true;
                break;
            }
        }

        if (!isSupportedMethod) {
            return KiwiwiError.HttpMethodNotSupported;
        }

        const raw = @embedFile("./templates/controller.kiwiwi");
        const rawPartial = @embedFile("./templates/controller.append.kiwiwi");
        const template = try std.fmt.allocPrint(arena.allocator(), raw, .{ firstArg, secondArgAsMethodCapitalized, thirdArg, fourthArg });
        const templatePartial = try std.fmt.allocPrint(arena.allocator(), rawPartial, .{ firstArg, secondArgAsMethodCapitalized, thirdArg, appendNameArg });
        const fileName = try std.fmt.allocPrint(arena.allocator(), "{s}.go", .{fileNameAsLowercase});

        std.debug.print("Generated controller template for {s}\n\n{s}\n\n", .{ fileName, template });
        try BoilerplateManager.write("controller", fileName, template, templatePartial);
        return;
    }

    fn generateService(serviceName: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const baseAllocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(baseAllocator);
        defer arena.deinit();

        const firstArg = try arena.allocator().dupe(u8, serviceName);
        firstArg[0] = std.ascii.toUpper(firstArg[0]);

        const secondArg = try arena.allocator().dupe(u8, serviceName);
        secondArg[0] = std.ascii.toLower(secondArg[0]);

        const appendNameArg = std.crypto.random.int(u16);

        const bufferServiceName = try arena.allocator().alloc(u8, serviceName.len);
        const fileNameAsLowercase = std.ascii.lowerString(bufferServiceName, serviceName);

        const raw = @embedFile("./templates/service.kiwiwi");
        const rawPartial = @embedFile("./templates/service.append.kiwiwi");

        const template = try std.fmt.allocPrint(arena.allocator(), raw, .{ firstArg, secondArg });
        const templatePartial = try std.fmt.allocPrint(arena.allocator(), rawPartial, .{ firstArg, secondArg, appendNameArg });
        const fileName = try std.fmt.allocPrint(arena.allocator(), "{s}.go", .{fileNameAsLowercase});

        std.debug.print("Generated service template for {s}\n\n{s}\n\n", .{ fileName, template });
        try BoilerplateManager.write("service", fileName, template, templatePartial);
        return;
    }
};

const BoilerplateManager = struct {
    fn ignore(context: []const u8) void {
        std.debug.print("{s}: no operation, ignoring\n\n", .{context});
    }

    fn write(directoryName: []const u8, fileName: []const u8, template: []const u8, templatePartial: []const u8) !void {
        std.fs.cwd().makeDir(directoryName) catch |err| switch (err) {
            std.fs.Dir.MakeError.PathAlreadyExists => {
                ignore("BoilerplateManager: write: PathAlreadyExists");
            },
            else => return err,
        };

        const openDirOptions: std.fs.Dir.OpenOptions = .{ .access_sub_paths = true, .iterate = true };
        var directory = try std.fs.cwd().openDir(directoryName, openDirOptions);
        defer directory.close();

        const createFileOptions: std.fs.File.CreateFlags = .{
            .exclusive = false,
            .lock = .shared,
            .read = true,
            .truncate = false, // handle appending contents
        };
        var file = try directory.createFile(fileName, createFileOptions);
        defer file.close();

        const stat = try file.stat();
        const is_empty = stat.size == 0;

        try file.seekFromEnd(0);
        const posBefore = try file.getPos();
        std.debug.print("check current cursor position: {d}.\n", .{posBefore});

        if (is_empty) {
            std.debug.print("should create a new file\n", .{});
            try file.writeAll(template);
            try file.sync();
        } else {
            std.debug.print("appending data to existing file\n", .{});
            try file.writeAll(templatePartial);
            try file.sync();
        }

        const posAfter = try file.getPos();

        std.debug.print("check current cursor position after write: {d}.\n", .{posAfter});
        std.debug.print("file create done.\n", .{});
    }
};

// @dev split test suites from implementation
test "Should reference all test cases" {
    std.testing.refAllDeclsRecursive(@This());
}
