//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const tests = @import("root_test.zig");

const KiwiwiError = error{
    InvalidTemplate,
    FlagKeyNotGiven,
    FlagValueNotGiven,
};

// 1. parse cli args
// 2. match template type
// 3. generate the template
// 4. display success message
pub fn Run() !void {
    const parsed = try TemplateGenerator.parseArgument();
    try TemplateGenerator.matchCallback(parsed.key, parsed.value);
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
};

const TemplateGenerator = struct {
    pub const tmlController = @embedFile("./templates/controller.kiwiwi");
    const tmlService = @embedFile("./templates/service.kiwiwi");

    fn parseArgument() !UserInput {
        var args = std.process.args();
        _ = args.next().?; // @dev ignore program name

        const flagKey = args.next() orelse return KiwiwiError.FlagKeyNotGiven;
        const flagValue = args.next() orelse return KiwiwiError.FlagValueNotGiven;

        return UserInput{
            .key = flagKey,
            .value = flagValue,
        };
    }

    fn matchCallback(key: []const u8, value: []const u8) !void {
        const isHelp = std.mem.eql(u8, key, "help") or std.mem.eql(u8, key, "h");
        const isVersion = std.mem.eql(u8, key, "version") or std.mem.eql(u8, key, "v");
        const isController = std.mem.eql(u8, key, "controller") or std.mem.eql(u8, key, "co");
        const isService = std.mem.eql(u8, key, "service") or std.mem.eql(u8, key, "s");

        if (isHelp) {
            printAppGuide();
            return;
        }
        if (isVersion) {
            printAppVersion();
            return;
        }
        if (isController) {
            try generateController(value);
            return;
        }
        if (isService) {
            try generateService(value);
            return;
        }
        return error.InvalidTemplate;
    }

    fn printAppGuide() void {
        const fl = FlagList.init();
        fl.print();
    }

    fn printAppVersion() void {
        std.debug.print("Kiwiwi version 1.0.0\n", .{});
    }

    // TODO add name and flag as params
    fn generateController(controllerName: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit(); // @dev ensure no memory leaks
        const allocator = gpa.allocator();

        const template = @embedFile("./templates/controller.kiwiwi");
        const tmpl = try std.fmt.allocPrint(allocator, template, .{controllerName});
        std.debug.print("Generated controller template for {s}\n\n", .{tmpl});

        defer allocator.free(tmpl);
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
