const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const ParseError = struct {
    msg: []const u8,
};

const ParseErrorArrayList = std.ArrayList(ParseError);
const StatementArrayList = std.ArrayList(ast.Statement);

const prefixParseFn = union(enum) {
    pub fn get(t: token.Token) ?*fn () ast.Expression {
        _ = t;
        return null;
    }
};
const infixParseFn = union(enum) {
    pub fn get(t: token.Token) ?*fn (ast.Expression) ast.Expression {
        _ = t;
        return null;
    }
};

const LOWEST = 1;
const EQUALS = 2;
const LESSGREATER = 3;
const SUM = 4;
const PRODUCT = 5;
const PREFIX = 6;
const CALL = 7;

const Parser = struct {
    const Self = @This();

    l: lexer.Lexer,
    curr_token: token.Token,
    peek_token: token.Token,
    errors: ParseErrorArrayList,
    alloc: std.mem.Allocator,

    pub fn new(l: lexer.Lexer) Self {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var p: Self = .{
            .l = l,
            .curr_token = undefined,
            .peek_token = undefined,
            .errors = ParseErrorArrayList.init(std.heap.page_allocator),
            .alloc = allocator,
        };
        p.next_token();
        p.next_token();
        return p;
    }
    fn peek_error(self: *Self, t: token.Token) void {
        const msg = std.fmt.allocPrint(std.heap.page_allocator, "Expected next token to be {s}, got {s} instead.", .{ token.get_type_str(t), token.get_type_str(self.peek_token) }) catch "Error creating error";
        const err = ParseError{ .msg = msg };

        self.errors.append(err) catch {
            std.debug.print("Error appending message\n", .{});
        };
    }

    fn next_token(self: *Self) void {
        self.curr_token = self.peek_token;
        self.peek_token = self.l.next_token();
    }

    fn parse_statement(self: *Self) ?ast.Statement {
        return switch (self.curr_token) {
            .LET => self.parse_let_statement(),
            .RETURN => self.parse_return_statement(),
            else => self.parse_expression_statement(),
        };
    }

    pub fn curr_token_is(self: Self, t: token.Token) bool {
        return switch (t) {
            .IDENT => blk: {
                switch (self.curr_token) {
                    .IDENT => break :blk true,
                    else => break :blk false,
                }
            },
            .INT => blk: {
                switch (self.curr_token) {
                    .INT => break :blk true,
                    else => break :blk false,
                }
            },
            else => std.mem.eql(u8, token.get_literal(self.curr_token), token.get_literal(t)),
        };
    }

    fn peek_token_is(self: Self, t: token.Token) bool {
        return switch (t) {
            .IDENT => blk: {
                switch (self.peek_token) {
                    .IDENT => break :blk true,
                    else => break :blk false,
                }
            },
            .INT => blk: {
                switch (self.peek_token) {
                    .INT => break :blk true,
                    else => break :blk false,
                }
            },
            else => std.mem.eql(u8, token.get_literal(self.peek_token), token.get_literal(t)),
        };
    }

    fn expect_peek(self: *Self, t: token.Token) bool {
        if (self.peek_token_is(t)) {
            self.next_token();
            return true;
        }
        self.peek_error(t);
        return false;
    }

    pub fn parse_let_statement(self: *Self) ?ast.Statement {
        if (!self.expect_peek(token.Token{ .IDENT = "" })) {
            return null;
        }
        var stmt = ast.Statement{ .LetStatement = .{ .token = self.curr_token, .name = ast.Identifier{ .token = self.curr_token, .value = token.get_literal(self.curr_token) }, .value = ast.Expression{ .ident = undefined } } };
        if (!self.expect_peek(token.Token.ASSIGN)) {
            return null;
        }
        while (!self.curr_token_is(token.Token.SEMICOLON) and !self.curr_token_is(token.Token.EOF)) {
            self.next_token();
        }
        return stmt;
    }

    pub fn parse_return_statement(self: *Self) ?ast.Statement {
        var stmt = ast.Statement{ .ReturnStatement = .{
            .token = self.curr_token,
            .return_value = undefined,
        } };
        self.next_token();
        while (!self.curr_token_is(token.Token.SEMICOLON) and !self.curr_token_is(token.Token.EOF)) {
            self.next_token();
        }
        return stmt;
    }

    fn parse_expression(self: Self, precedence: i32) ?ast.Expression {
        _ = precedence;
        var prefix = prefixParseFn.get(self.curr_token);
        if (prefix) |p| {
            return p.*();
        }
        return null;
    }

    pub fn parse_expression_statement(self: *Self) ?ast.Statement {
        var stmt = ast.Statement{ .ExpressionStatement = .{
            .token = self.curr_token,
            .expression = .{ .ident = undefined },
        } };
        if (self.parse_expression(LOWEST)) |exp| {
            stmt.ExpressionStatement.expression = exp;
        }
        if (self.peek_token_is(token.Token.SEMICOLON)) {
            self.next_token();
        }
        return stmt;
    }

    pub fn parse_program(self: *Self) !?ast.Program {
        var program = ast.Program{ .stmt_idx = 0, .statements = StatementArrayList.init(std.heap.page_allocator) };
        while (!self.curr_token_is(token.Token.EOF)) {
            if (self.parse_statement()) |stmt| {
                try program.statements.append(stmt);
            }
            self.next_token();
        }
        return program;
    }
};

test "parse_let_statement" {
    const input = "let x = 5;";
    var l = lexer.Lexer.new(input);
    var parser = Parser.new(l);
    _ = parser.parse_let_statement();
}

test "curr_token_is" {
    const input = "let x = 5;";
    var l = lexer.Lexer.new(input);
    var parser = Parser.new(l);
    try std.testing.expect(parser.curr_token_is(token.Token.LET));
    parser.next_token();
    try std.testing.expect(parser.curr_token_is(token.Token{ .IDENT = "" }));
    parser.next_token();
    try std.testing.expect(parser.curr_token_is(token.Token.ASSIGN));
    parser.next_token();
    try std.testing.expect(parser.curr_token_is(token.Token{ .INT = "5" }));
    parser.next_token();
    try std.testing.expect(parser.curr_token_is(token.Token.SEMICOLON));
}

test "let_statement" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    if (try p.parse_program()) |program| {
        const Test = struct { t: []const u8 };
        const tests: [3]Test = .{ .{ .t = "x" }, .{ .t = "y" }, .{ .t = "foobar" } };
        for (tests, 0..) |tst, i| {
            const stmt: ast.Statement = program.statements.items[i];
            try std.testing.expectEqualStrings(stmt.LetStatement.name.value, tst.t);
        }
    } else {
        std.debug.print("parse_program() returned null\n", .{});
    }
}

test "let_statement_errors" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let 838383;
    ;

    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    // if the previous test passes, then we already know that parese_program
    // works on this input
    _ = try p.parse_program();
    const errors: ParseErrorArrayList = p.errors;
    try std.testing.expectEqual(errors.items.len, 1);
}

test "return_statement" {
    const input =
        \\return 5;
        \\ return 10;
        \\ return 993322;
    ;
    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    if (try p.parse_program()) |program| {
        if (program.statements.items.len != 3) {
            std.debug.print("Error: program.statements does not contain 3 statements\n", .{});
        }
        for (program.statements.items) |stmt| {
            switch (stmt) {
                .ReturnStatement => {
                    try std.testing.expectEqualStrings(stmt.ReturnStatement.token_literal(), "return");
                },
                else => {
                    std.debug.print("Error: statement is not a return statement\n", .{});
                },
            }
        }
    }
}

test "identifier_expression" {
    const input = "foobar;";
    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    if (try p.parse_program()) |program| {
        if (program.statements.getLastOrNull()) |stmt| {
            // std.debug.print("STATEMENT: {?}\n", .{stmt});
            var ident = stmt.ExpressionStatement.expression.ident;
            try std.testing.expectEqualStrings("foobar", ident.value);
        } else {
            std.debug.print("Error: program does not have enough statements.\n", .{});
        }
    }
}
