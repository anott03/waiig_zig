const std = @import("std");
const t = @import("token.zig");

const Program = struct {
    const Self = @This();
    statements: ?[]Statement,
    pub fn token_literal(self: Self) []const u8 {
        if (self.statements) |statements| {
            return statements[0].token_literal();
        }
        return "";
    }
};
const Statement = struct {
    name: Identifier,
    value: Expression,
};
const Identifier = struct {
    const Self = @This();
    token: t.Token.IDENT,
    value: []const u8,

    fn expression_node(self: Self) void {
        _ = self;
    }
    fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
};
const Expression = struct {
    pub fn token_literal() []const u8 {
        return "";
    }
    fn expression_node() void {}
};
const LetStatement = struct {
    const Self = @This();
    token: t.Token.LET,
    name: Identifier,
    value: Expression,

    fn statement_node(self: Self) void {
        _ = self;
    }
    fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
};

test "struct" {
    std.debug.print("hello, world\n", .{});
}
