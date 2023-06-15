const std = @import("std");
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

    fn next_token(self: *Self) void {
        self.curr_token = self.peek_token;
        self.peek_token = self.l.next_token();
    }

    fn parse_statement(self: *Self) ?ast.Statement {
        return switch (self.curr_token) {
            .LET => self.parse_let_statement(),
            else => null,
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
        return false;
    }

    pub fn parse_let_statement(self: *Self) ?ast.Statement {
        if (!self.expect_peek(token.Token{ .IDENT = "" })) {
            return null;
        }
        var stmt = ast.Statement{ .LetStatement = .{ .token = self.curr_token, .name = ast.Identifier{ .token = self.curr_token, .value = token.get_literal(self.curr_token) }, .value = ast.Expression{} } };
        if (!self.expect_peek(token.Token.ASSIGN)) {
            return null;
        }
        while (!self.curr_token_is(token.Token.SEMICOLON)) {
            std.debug.print("looping parse_let_statement\n", .{});
            self.next_token();
        }
        return stmt;
    }

    pub fn parse_program(self: *Self) !?ast.Program {
        var program = ast.Program{ .stmt_idx = 0, .statements = null };
        program.statements = std.heap.page_allocator.alloc(ast.Statement, 10) catch null;
        if (program.statements == null) {
            return null;
        }
        while (!self.curr_token_is(token.Token.EOF)) {
            std.debug.print("looping parse_program\n", .{});
            if (self.parse_statement()) |stmt| {
                if (program.statements) |*statements| {
                    statements.*[program.stmt_idx] = stmt;
                    program.stmt_idx += 1;
                }
                if (program.statements.?.len == program.stmt_idx) {
                    var old_stmts = program.statements.?;
                    program.statements = std.heap.page_allocator.alloc(ast.Statement, program.stmt_idx * 2 + 1) catch null;
                    for (old_stmts, 0..) |statement, i| {
                        if (program.statements) |*statements| {
                            statements.*[i] = statement;
                        }
                    }
                    std.heap.page_allocator.free(old_stmts);
                }
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
    parser.parse_let_statement();
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
    // const input =
    //     \\let x = 5;
    //     \\let y = 10;
    //     \\let foobar = 838383
    // ;
    //
    // var l = lexer.Lexer.new(input);
    // var p = Parser.new(l);
    // if (try p.parse_program()) |program| {
    //     std.debug.print("parse_program() did not return null\n", .{});
    //     std.debug.print("{?}\n", .{program});
    //     // try std.testing.expectEqual(program.statements.?.len, 3);
    //     // const Test = struct {
    //     //     t: []const u8,
    //     // };
    //     //const tests: [3]Test = .{ .{ .t = "x" }, .{ .t = "y" }, .{ .t = "foobar" } };
    //     // for (tests, 0..) |tst, i| {
    //     //     if (program.statements) |statements| {
    //     //         const stmt: ast.Statement = statements[i];
    //     //         try std.testing.expectEqualStrings(stmt.name.value, tst.t);
    //     //     }
    //     // }
    // } else {
    //     std.debug.print("parse_program() returned null\n", .{});
    // }
}
