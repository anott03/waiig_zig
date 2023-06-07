const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const PROMPT = ">> ";

pub fn start() !void {
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;
    while (true) {
        std.debug.print("{s}", .{PROMPT});
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var l = lexer.Lexer.new(line);
            var tok = l.next_token();
            while (tok != token.Token.EOF) {
                std.debug.print("{?}\n", .{tok});
                tok = l.next_token();
            }
        }
    }
}
