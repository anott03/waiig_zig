const std = @import("std");
const repl = @import("repl.zig");

pub fn main() !void {
    std.debug.print("Hello! Welcome to the Monkey repl!\n", .{});
    try repl.start();
}
