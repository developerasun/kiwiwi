const std = @import("std");
const kiwiwi = @import("kiwiwi");

pub fn main() !void {
    kiwiwi.metadata();
    const controllerName = try kiwiwi.ParseArgument();
    try kiwiwi.Generate(controllerName);
}
