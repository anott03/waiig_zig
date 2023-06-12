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

    fn parse_statement(self: Self) ?ast.Statement {
        return switch (self.curr_token) {
            .LET => self.parse_let_statement(),
            else => null,
        };
    }

    fn parse_let_statement(self: *Self) ast.LetStatement {
        _ = self;
        var stmt = ast.LetStatement{};
        _ = stmt;
    }

    pub fn parse_program(self: *Self) !?ast.Program {
        var program = ast.Program{ .stmt_idx = 0, .statements = null };
        program.statements = std.heap.page_allocator.alloc(ast.Statement, 10) catch null;
        if (program.statements == null) {
            return null;
        }
        while (self.curr_token != token.Token.EOF) {
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

test "let_statement" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383
    ;

    var l = lexer.Lexer.new(input);
    var p = Parser.new(l);
    if (try p.parse_program()) |program| {
        try std.testing.expectEqual(program.statements.?.len, 3);
        const Test = struct {
            t: []const u8,
        };
        const tests: [3]Test = .{ .{ .t = "x" }, .{ .t = "y" }, .{ .t = "foobar" } };
        for (tests, 0..) |tst, i| {
            if (program.statements) |statements| {
                const stmt: ast.Statement = statements[i];
                try std.testing.expectEqualStrings(stmt.name.value, tst.t);
            }
        }
    } else {
        std.debug.print("parse_program() returned null\n", .{});
    }
}
