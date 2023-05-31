const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const PROMPT = ">> ";

pub fn start() !void {
    const stdin = std.io.getStdIn().reader();
    var buf: [80]u8 = undefined;
    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        var l = lexer.Lexer.new(line);
        var tok = l.next_token() catch {
            std.debug.print("Error getting next token");
            return;
        };
        while (tok != token.Token.EOF) {
            std.debug.print("{?}\n", .{tok});
            tok = l.next_token() catch {
                std.debug.print("Error getting next token");
                return;
            };
        }
    }
}
