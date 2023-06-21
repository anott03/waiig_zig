const std = @import("std");
const t = @import("token.zig");

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
    pub fn to_string(self: Self) []const u8 {
        return self.value;
    }
};
pub const Expression = struct {
    const Self = @This();
    ident: Identifier,
    pub fn token_literal() []const u8 {
        return "";
    }
    fn expression_node() void {}
    pub fn to_string(self: Self) []const u8 {
        return self.ident.to_string();
    }
};
pub const ExpressionStatement = struct {
    const Self = @This();
    token: t.Token,
    expression: Expression,
    pub fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
    pub fn to_string(self: *Self) []const u8 {
        _ = self;
    }
};
pub const IntegerLiteral = struct {
    const Self = @This();
    token: t.Token,
    value: i64,
    pub fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
    pub fn to_string(self: Self) []const u8 {
        return self.token_literal();
    }
};
pub const LetStatement = struct {
    const Self = @This();
    token: t.Token,
    name: Identifier,
    value: Expression,

    fn statement_node(self: Self) void {
        _ = self;
    }
    pub fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
    pub fn to_string(self: *Self) []const u8 {
        _ = self;
    }
};
pub const ReturnStatement = struct {
    const Self = @This();
    token: t.Token,
    return_value: Expression,
    fn statement_node(self: Self) void {
        _ = self;
    }
    pub fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
    pub fn to_string(self: *Self) []const u8 {
        _ = self;
    }
};
pub const Statement = union(enum) {
    LetStatement: LetStatement,
    ReturnStatement: ReturnStatement,
    ExpressionStatement: ExpressionStatement,
    IntegerLiteral: IntegerLiteral,
};
pub const Program = struct {
    const Self = @This();
    statements: std.ArrayList(Statement),
    stmt_idx: usize,
    pub fn token_literal(self: Self) []const u8 {
        if (self.statements) |statements| {
            return statements[0].token_literal();
        }
        return "";
    }
    pub fn to_string(self: *Self) []const u8 {
        for (self.statements) |stmt| {
            _ = stmt;
        }
    }
};

test "to_string" {
    // TODO: create a program with a series of statements and test that to_string
    // produces the correct Monkey source from it.
}
