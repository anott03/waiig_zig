const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const StringArrayList = std.ArrayList([]const u8);

const Parser = struct {
    const Self = @This();

    l: lexer.Lexer,
    curr_token: token.Token,
    peek_token: token.Token,
    errors: StringArrayList,
    alloc: std.mem.Allocator,

    pub fn new(l: lexer.Lexer) Self {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var p: Self = .{
            .l = l,
            .curr_token = undefined,
            .peek_token = undefined,
            .errors = StringArrayList.init(allocator),
            .alloc = allocator,
        };
        p.next_token();
        p.next_token();
        return p;
    }

    fn errors(self: Self) StringArrayList {
        return self.errors;
    }

    fn peek_error(self: *Self, t: token.Token) void {
        const msg = std.fmt.allocPrint(self.alloc, "Expected next token to be {s}, got {s} instead.", .{ token.get_type_str(t), token.get_type_str(self.peek_token) }) catch "Error creating error";
        defer self.alloc.free(msg);
        self.errors.append(msg) catch {
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
        self.peek_error(t);
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
        while (!self.curr_token_is(token.Token.SEMICOLON) and !self.curr_token_is(token.Token.EOF)) {
            self.next_token();
        }
        return stmt;
    }

    pub fn parse_program(self: *Self) !?ast.Program {
        var program = ast.Program{ .stmt_idx = 0, .statements = null };
        program.statements = self.alloc.alloc(ast.Statement, 10) catch null;
        if (program.statements == null) {
            return null;
        }
        while (!self.curr_token_is(token.Token.EOF)) {
            if (self.parse_statement()) |stmt| {
                if (program.statements) |*statements| {
                    statements.*[program.stmt_idx] = stmt;
                    program.stmt_idx += 1;
                }
                if (program.statements.?.len == program.stmt_idx) {
                    var old_stmts = program.statements.?;
                    program.statements = self.alloc.alloc(ast.Statement, program.stmt_idx * 2 + 1) catch null;
                    for (old_stmts, 0..) |statement, i| {
                        if (program.statements) |*statements| {
                            statements.*[i] = statement;
                        }
                    }
                    self.alloc.free(old_stmts);
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
            if (program.statements) |statements| {
                const stmt: ast.Statement = statements[i];
                try std.testing.expectEqualStrings(stmt.LetStatement.name.value, tst.t);
            }
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
    const errors = p.errors;
    std.debug.print("{any}\n", .{errors.items});
}
