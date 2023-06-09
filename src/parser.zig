const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const ParseError = struct {
    msg: []const u8,
};

const ParseErrorArrayList = std.ArrayList(ParseError);
const StatementArrayList = std.ArrayList(ast.Statement);

fn parse_prefix_expression(p: *Parser) ast.Expression {
    var expression = ast.Expression{ .PrefixExpression = .{
        .token = p.curr_token,
        .operator = token.get_literal(p.curr_token),
        .right = undefined,
    } };
    var mem = p.alloc.alloc(ast.Expression, 1) catch null;
    if (p.parse_expression(PREFIX)) |exp| {
        // expression.PrefixExpression.right = &exp;
        if (mem) |*mut_mem| {
            mut_mem.*[0] = .{
                .PrefixExpression = exp.PrefixExpression,
            };
        }
        if (mem) |m| {
            expression.PrefixExpression.right = &m[0];
        }
    }
    p.next_token();
    return expression;
}
fn parse_integer_literal(p: *Parser) ast.Expression {
    var literal = ast.Expression{ .IntegerLiteral = .{
        .token = p.curr_token,
        .value = std.fmt.parseInt(i32, token.get_literal(p.curr_token), 10) catch -1,
    } };
    return literal;
}
fn parse_identifier(p: *Parser) ast.Expression {
    return ast.Expression{ .Identifier = .{
        .token = p.curr_token,
        .value = token.get_literal(p.curr_token),
    } };
}
fn get_prefix_parse_fn(t: token.Token) ?*const fn (p: *Parser) ast.Expression {
    return switch (t) {
        .IDENT => &parse_identifier,
        .INT => &parse_integer_literal,
        .BANG => &parse_prefix_expression,
        .MINUS => &parse_prefix_expression,
        else => null,
    };
}
pub fn get_infix_parse_fn(t: token.Token) ?*const fn (p: *Parser, e: ast.Expression) ast.Expression {
    _ = t;
    return null;
}

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
    arena: std.heap.ArenaAllocator,

    pub fn new(l: lexer.Lexer) Self {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var arena = std.heap.ArenaAllocator.init(allocator);
        var p: Self = .{ .l = l, .curr_token = undefined, .peek_token = undefined, .errors = ParseErrorArrayList.init(std.heap.page_allocator), .alloc = arena.allocator(), .arena = arena };
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
        var exp = self.alloc.alloc(ast.Expression, 1) catch null;
        var stmt = ast.Statement{ .LetStatement = .{ .token = self.curr_token, .name = ast.Identifier{ .token = self.curr_token, .value = token.get_literal(self.curr_token) }, .value = undefined } };
        if (exp) |*mut_exp| {
            mut_exp.*[0] = .{
                .Identifier = undefined,
            };
        }
        if (exp) |e| {
            stmt.LetStatement.value = &e[0];
        }
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

    fn parse_expression(self: *Self, precedence: i32) ?ast.Expression {
        _ = precedence;
        var prefix = get_prefix_parse_fn(self.curr_token);
        if (prefix) |p| {
            return p(self);
        }
        return null;
    }

    pub fn parse_expression_statement(self: *Self) ?ast.Statement {
        var exp = self.alloc.alloc(ast.Expression, 1) catch null;
        if (self.parse_expression(LOWEST)) |e| {
            // stmt.ExpressionStatement.expression = exp;
            if (exp) |*mut_exp| {
                mut_exp.*[0] = e;
            }
        }
        var stmt = ast.Statement{ .ExpressionStatement = .{
            .token = self.curr_token,
            .expression = undefined,
        } };
        if (exp) |e| {
            stmt.ExpressionStatement.expression = &e[0];
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
    defer p.arena.deinit();
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
    defer p.arena.deinit();
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
    defer p.arena.deinit();
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
    defer p.arena.deinit();
    if (try p.parse_program()) |program| {
        if (program.statements.getLastOrNull()) |stmt| {
            switch (stmt) {
                .ExpressionStatement => {
                    // switch (stmt.ExpressionStatement.expression) {
                    //     .Identifier => {
                    //         try std.testing.expectEqualStrings("foobar", stmt.ExpressionStatement.expression.Identifier.value);
                    //     },
                    //     else => {
                    //         std.debug.print("Error: ExpressionStatement.expression is not an Identifier\n", .{});
                    //     },
                    // }
                },
                else => {
                    std.debug.print("Error: stmt is not an ExpressionStatement", .{});
                },
            }
        } else {
            std.debug.print("Error: no statements in program\n", .{});
        }
    } else {
        std.debug.print("Error: parse_program returned null\n", .{});
    }
}

test "int_literal_expression" {
    const input = "5;";
    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    defer p.arena.deinit();
    if (try p.parse_program()) |program| {
        if (program.statements.getLastOrNull()) |stmt| {
            switch (stmt) {
                .ExpressionStatement => {
                    switch (stmt.ExpressionStatement.expression.*) {
                        .IntegerLiteral => {
                            try std.testing.expect(5 == stmt.ExpressionStatement.expression.IntegerLiteral.value);
                        },
                        else => {
                            std.debug.print("Error: ExpressionStatement.expression is not an IntegerLiteral\n", .{});
                        },
                    }
                },
                else => {
                    std.debug.print("Error: stmt is not an ExpressionStatement", .{});
                },
            }
        } else {
            std.debug.print("Error: no statements in program\n", .{});
        }
    } else {
        std.debug.print("Error: parse_program returned null\n", .{});
    }
}

test "prefix_expressions" {
    const prefix_test = struct {
        input: []const u8,
        operator: []const u8,
        int_val: i32,
    };
    const prefix_tests: [2]prefix_test = .{
        .{ .input = "!5;", .operator = "!", .int_val = 5 },
        .{ .input = "-15;", .operator = "-", .int_val = 15 },
    };
    for (prefix_tests) |tst| {
        var l = lexer.Lexer.new(tst.input);
        var p = Parser.new(l);
        defer p.arena.deinit();
        if (try p.parse_program()) |program| {
            if (program.statements.getLastOrNull()) |stmt| {
                _ = stmt;
            } else {
                std.debug.print("Error: program has no statements\n", .{});
            }
        } else {
            std.debug.print("Error: parse_program returned null\n", .{});
        }
    }
}
