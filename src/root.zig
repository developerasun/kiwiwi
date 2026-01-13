//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const tests = @import("root_test.zig");

const KiwiwiError = error{
    InvalidTemplate,
    InvalidCallback,
    FlagNotSupported,
    FlagKeyNotGiven,
    FlagValueNotGiven,
    FlagNotEnoughArguments,
    HttpMethodNotSupported,
    UndefinedBehavior,
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
            return KiwiwiError.FlagValueNotGiven;
        };

        if (std.mem.eql(u8, flagKey, "controller") or std.mem.eql(u8, flagKey, "co")) {
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
            return UserInput{
                .key = flagKey,
                .value = flagValue,
                .callback = CallbackType.service,
                .httpMethod = null,
            };
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
        std.debug.print("Kiwiwi version 0.3.0\n", .{});
    }

    fn printAppSymbol() void {
        std.debug.print("\n{s}\n\n", .{AscilArtStore.kiwi});
    }

    fn generateController(controllerName: []const u8, httpMethod: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const baseAllocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(baseAllocator);
        defer arena.deinit();

        const outputUpper = try arena.allocator().alloc(u8, httpMethod.len);
        const methodUpper = std.ascii.upperString(outputUpper, httpMethod);
        var namedCopiedAsPrivate = try arena.allocator().dupe(u8, controllerName);
        namedCopiedAsPrivate[0] = std.ascii.toLower(namedCopiedAsPrivate[0]); // handle go's access modifier. lower for private, upper for public.

        var isSupportedMethod = false;
        for (FlagList.default_http_methods) |method| {
            if (std.mem.eql(u8, method, methodUpper)) {
                isSupportedMethod = true;
                break;
            }
        }

        if (!isSupportedMethod) {
            return KiwiwiError.HttpMethodNotSupported;
        }

        const raw = @embedFile("./templates/controller.kiwiwi");
        const template = try std.fmt.allocPrint(arena.allocator(), raw, .{ controllerName, methodUpper, namedCopiedAsPrivate });
        const fileName = try std.fmt.allocPrint(arena.allocator(), "{s}.go", .{namedCopiedAsPrivate});

        std.debug.print("Generated controller template for {s}\n\n{s}\n\n", .{ fileName, template });
        try BoilerplateManager.write("controller", fileName, template);
        return;
    }

    fn generateService(serviceName: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const baseAllocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(baseAllocator);
        defer arena.deinit();

        const raw = @embedFile("./templates/service.kiwiwi");
        const template = try std.fmt.allocPrint(arena.allocator(), raw, .{serviceName});
        var serviceNameCopied = try arena.allocator().dupe(u8, serviceName);
        serviceNameCopied[0] = std.ascii.toLower(serviceNameCopied[0]);
        const fileName = try std.fmt.allocPrint(arena.allocator(), "{s}.go", .{serviceNameCopied});

        std.debug.print("Generated service template for {s}\n\n{s}\n\n", .{ fileName, template });
        try BoilerplateManager.write("service", fileName, template);
        return;
    }
};

const BoilerplateManager = struct {
    fn ignore(context: []const u8) void {
        std.debug.print("{s}: no operation, ignoring\n\n", .{context});
    }

    fn write(directoryName: []const u8, fileName: []const u8, template: []const u8) !void {
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

        const newFileContent = template;
        const existingFileContent = "func myController() error { return nil }\n\n";

        if (is_empty) {
            std.debug.print("should create a new file\n", .{});
            try file.writeAll(newFileContent);
            try file.sync();
        } else {
            std.debug.print("appending data to existing file\n", .{});
            try file.writeAll(existingFileContent);
            try file.sync();
        }

        const posAfter = try file.getPos();

        std.debug.print("check current cursor position after write: {d}.\n", .{posAfter});
        std.debug.print("file create done.\n", .{});
    }
};

const AscilArtStore = struct {
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
};

// @dev split test suites from implementation
test "Should reference all test cases" {
    std.testing.refAllDeclsRecursive(@This());
}
