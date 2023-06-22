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
pub const PrefixExpression = struct {
    const Self = @This();
    token: t.Token,
    operator: []const u8,
    right: *Expression,

    pub fn token_literal(self: Self) []const u8 {
        return t.get_literal(self.token);
    }
    pub fn to_string(self: Self) []const u8 {
        _ = self;
        return "";
    }
};
pub const IntegerLiteral = struct {
    const Self = @This();
    token: t.Token,
    value: i32,
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
pub const Expression = union(enum) {
    Identifier: Identifier,
    IntegerLiteral: IntegerLiteral,
    PrefixExpression: PrefixExpression,
};
pub const Statement = union(enum) {
    LetStatement: LetStatement,
    ReturnStatement: ReturnStatement,
    ExpressionStatement: ExpressionStatement,
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
