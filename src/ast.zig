const std = @import("std");
const t = @import("token.zig");

pub const Program = struct {
    const Self = @This();
    statements: ?[]Statement,
    stmt_idx: usize,
    pub fn token_literal(self: Self) []const u8 {
        if (self.statements) |statements| {
            return statements[0].token_literal();
        }
        return "";
    }
};
pub const Statement = struct {
    name: Identifier,
    value: Expression,
};
pub const Identifier = struct {
    const Self = @This();
    token: t.Token,
    value: []const u8,

    fn expression_node(self: Self) void {
        _ = self;
    }
    fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
};
pub const Expression = struct {
    pub fn token_literal() []const u8 {
        return "";
    }
    fn expression_node() void {}
};
pub const LetStatement = struct {
    const Self = @This();
    token: t.Token,
    name: Identifier,
    value: Expression,

    fn statement_node(self: Self) void {
        _ = self;
    }
    fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
};

test "struct" {}
