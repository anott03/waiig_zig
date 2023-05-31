const std = @import("std");
const Lexer = @import("./lexer.zig").Lexer;
const token = @import("./token.zig");

const testing = @import("std").testing;
test "lexer full statement" {
    const input = "let five = 5;";
    var lexer = Lexer.new(input);
    var t: token.Token = lexer.next_token();
    try testing.expectEqual(token.Token.LET, t);
    t = lexer.next_token();
    try testing.expectEqualStrings("five", t.IDENT);
    t = lexer.next_token();
    try testing.expectEqual(token.Token.ASSIGN, t);
    t = lexer.next_token();
    try testing.expectEqual(token.Token.INT, t);
}
test "lexer.assign" {
    const input = "=";
    var lexer = Lexer.new(input);
    try testing.expectEqual(lexer.ch, '=');
}

test "lexer.small_test" {
    const input = "let five = 5;";
    var lexer = Lexer.new(input);
    var t = lexer.next_token();
    try testing.expectEqual(token.Token.LET, t);
}

test "lexer.two_char_token" {
    const input = "10 == 10";
    var lexer = Lexer.new(input);
    _ = lexer.next_token();
    const t = lexer.next_token();
    try testing.expectEqual(token.Token.EQ, t);
}

test "lexer.keyword" {
    const input = "let add = fn(x, y) { x + y; };";
    var lexer = Lexer.new(input);
    var t = lexer.next_token();
    try testing.expectEqual(token.Token.LET, t);
    for (0..2) |_| {
        _ = lexer.next_token();
    }
    t = lexer.next_token();
    try testing.expectEqual(token.Token.FUNCTION, t);
}

test "lexer.semicolon" {
    const input = "10 == 10;";
    var lexer = Lexer.new(input);
    for (0..3) |_| {
        _ = lexer.next_token();
    }
    const t = lexer.next_token();
    try testing.expectEqual(token.Token.SEMICOLON, t);
}

test "lexer.big_test" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\    x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\10 == 10;
        \\10 != 10;
    ;
    const corrects: [73]token.Token = .{
        token.Token.LET,
        token.Token{ .IDENT = "five" },
        token.Token.ASSIGN,
        token.Token{ .INT = "5" },
        token.Token.SEMICOLON,
        token.Token.LET,
        token.Token{ .IDENT = "ten" },
        token.Token.ASSIGN,
        token.Token{ .INT = "10" },
        token.Token.SEMICOLON,
        token.Token.LET,
        token.Token{ .IDENT = "add" },
        token.Token.ASSIGN,
        token.Token.FUNCTION,
        token.Token.LPAREN,
        token.Token{ .IDENT = "x" },
        token.Token.COMMA,
        token.Token{ .IDENT = "y" },
        token.Token.RPAREN,
        token.Token.LSQUIRLY,
        token.Token{ .IDENT = "x" },
        token.Token.PLUS,
        token.Token{ .IDENT = "y" },
        token.Token.SEMICOLON,
        token.Token.RSQUIRLY,
        token.Token.SEMICOLON,
        token.Token.LET,
        token.Token{ .IDENT = "result" },
        token.Token.ASSIGN,
        token.Token{ .IDENT = "add" },
        token.Token.LPAREN,
        token.Token{ .IDENT = "five" },
        token.Token.COMMA,
        token.Token{ .IDENT = "ten" },
        token.Token.RPAREN,
        token.Token.SEMICOLON,
        token.Token.BANG,
        token.Token.MINUS,
        token.Token.SLASH,
        token.Token.ASTERISK,
        token.Token{ .INT = "5" },
        token.Token.SEMICOLON,
        token.Token{ .INT = "5" },
        token.Token.LT,
        token.Token{ .INT = "10" },
        token.Token.GT,
        token.Token{ .INT = "5" },
        token.Token.IF,
        token.Token.LPAREN,
        token.Token{ .INT = "5" },
        token.Token.LT,
        token.Token{ .INT = "10" },
        token.Token.RPAREN,
        token.Token.LSQUIRLY,
        token.Token.RETURN,
        token.Token.TRUE,
        token.Token.SEMICOLON,
        token.Token.RSQUIRLY,
        token.Token.ELSE,
        token.Token.LSQUIRLY,
        token.Token.RETURN,
        token.Token.FALSE,
        token.Token.SEMICOLON,
        token.Token.RSQUIRLY,
        token.Token{ .INT = "10" },
        token.Token.EQ,
        token.Token{ .INT = "10" },
        token.Token.SEMICOLON,
        token.Token{ .INT = "10" },
        token.Token.NEQ,
        token.Token{ .INT = "10" },
        token.Token.SEMICOLON,
        token.Token.EOF,
    };
    var lexer = Lexer.new(input);
    for (corrects, 0..) |correct, i| {
        _ = i;
        var t = lexer.next_token();
        switch (correct) {
            .IDENT => try testing.expectEqualStrings(correct.IDENT, t.IDENT),
            .INT => try testing.expectEqualStrings(correct.INT, t.INT),
            else => try testing.expectEqual(correct, t),
        }
        std.debug.print("{?}\n", .{t});
        // std.debug.print("pass {}\n{c}\n", .{ i, lexer.ch });
    }
}
