const token = @import("token.zig");

pub const Statement = struct {
    const Self = @This();

    pub fn token_literal(self: Self) []const u8 {
        _ = self;
        return "";
    }

    pub fn statement_node() void {}
};

pub const Expression = struct {
    const Self = @This();

    pub fn token_literal(self: Self) []const u8 {
        _ = self;
        return "";
    }

    pub fn expression_node() void {}
};

pub const Program = struct {
    const Self = @This();
    statements: []Statement,

    pub fn token_literal(self: Self) []const u8 {
        if (self.statements.len > 0) {
            return self.statements[0].token_literal();
        } else {
            return "";
        }
    }
};

pub const LetStatement = struct {
    const Self = @This();

    token: token.Token,
    name: *Identifier,
    value: Expression,

    pub fn statement_node() void {}
    pub fn token_literal(self: Self) []const u8 {
        token.get_literal(self.token);
    }
};

pub const Identifier = struct {
    const Self = @This();

    token: token.Token,
    value: []const u8,

    pub fn expression_node() void {}
    pub fn token_literal(self: Self) []const u8 {
        return token.get_literal(self.token);
    }
};
