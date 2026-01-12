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
    try TemplateGenerator.matchCallback(parsed.callback, parsed.value);

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
        .{ .name = "help", .alias = "h", .description = "Display help information" },
        .{ .name = "version", .alias = "v", .description = "Display version information" },
        .{ .name = "controller", .alias = "co", .description = "Generate a controller template" },
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
};

const CallbackType = enum {
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
            if (std.mem.eql(u8, flagKey, "help") or std.mem.eql(u8, flagKey, "h")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.help,
                };
            }

            if (std.mem.eql(u8, flagKey, "version") or std.mem.eql(u8, flagKey, "v")) {
                return UserInput{
                    .key = flagKey,
                    .value = fallbackValue,
                    .callback = CallbackType.version,
                };
            }
            return KiwiwiError.FlagValueNotGiven;
        };

        if (std.mem.eql(u8, flagKey, "controller") or std.mem.eql(u8, flagKey, "co")) {
            const httpMethod = args.next() orelse {
                return KiwiwiError.FlagNotEnoughArguments;
            };
            std.debug.print("method: {s}\n", .{httpMethod});
            return UserInput{
                .key = flagKey,
                .value = flagValue,
                .callback = CallbackType.controller,
            };
        }

        if (std.mem.eql(u8, flagKey, "service") or std.mem.eql(u8, flagKey, "s")) {
            return UserInput{
                .key = flagKey,
                .value = flagValue,
                .callback = CallbackType.service,
            };
        }

        return KiwiwiError.UndefinedBehavior;
    }

    fn matchCallback(callback: CallbackType, value: []const u8) !void {
        switch (callback) {
            .service => {
                try generateService(value);
                return;
            },
            .controller => {
                try generateController(value, "get");
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
        }

        return KiwiwiError.InvalidCallback;
    }

    fn printAppGuide() void {
        const fl = FlagList.init();
        fl.print();
    }

    fn printAppVersion() void {
        std.debug.print("Kiwiwi version 1.0.0\n", .{});
    }

    fn generateController(controllerName: []const u8, httpMethod: []const u8) !void {
        for (FlagList.default_http_methods) |method| {
            if (std.mem.eql(u8, method, httpMethod)) {
                break;
            } else {
                return KiwiwiError.HttpMethodNotSupported;
            }
        }

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const allocator = gpa.allocator();

        const raw = @embedFile("./templates/controller.kiwiwi");
        const template = try std.fmt.allocPrint(allocator, raw, .{ controllerName, "GET", "get" });
        std.debug.print("Generated controller template for {s}\n\n", .{template});

        defer allocator.free(template);
        return;
    }

    fn generateService(serviceName: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const allocator = gpa.allocator();

        const template = @embedFile("./templates/service.kiwiwi");
        const tmpl = try std.fmt.allocPrint(allocator, template, .{serviceName});
        std.debug.print("Generated service template for {s}\n\n", .{tmpl});

        defer allocator.free(tmpl);
        return;
    }
};

// @dev split test suites from implementation
test "Should reference all test cases" {
    std.testing.refAllDeclsRecursive(@This());
}
