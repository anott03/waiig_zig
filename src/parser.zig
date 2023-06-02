const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("tokne.zig");
const ast = @import("ast.zig");

pub const Parser = struct {
    const Self = @This();

    l: lexer.Lexer,
    curr_token: token.Token,
    peek_token: token.Token,

    pub fn new(l: *lexer.Lexer) Self {
        var p: Parser = .{ .l = l };
        p.next_token();
        p.next_token();
        return p;
    }

    pub fn next_token(self: *Self) void {
        self.curr_token = self.peek_token;
        self.peek_token = self.l.next_token();
    }

    pub fn parse_program(self: *Self) ?ast.Program {
        _ = self;
        return null;
    }
};

test "let_statement" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    var program: ?ast.Program = p.parse_program();
    if (program == null) {
        std.debug.print("Error", .{});
    } else {
        std.testing.expectEqual(3, program.?.statements.len);
        for (program.?.statements) |statement| {
            _ = statement;
        }
    }
}
