const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const Parser = struct {
    const Self = @This();

    l: lexer.Lexer,
    curr_token: token.Token,
    peek_token: token.Token,

    pub fn new(l: lexer.Lexer) Self {
        var p: Self = .{
            .l = l,
            .curr_token = undefined,
            .peek_token = undefined,
        };
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
