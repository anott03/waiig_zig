const std = @import("std");
const Lexer = @import("./lexer.zig").Lexer;
const token = @import("./token.zig");

const testing = @import("std").testing;
test "lexer full statement" {
    const input = "let five = 5;";
    var lexer = Lexer.new(input);
    var t: token.Token = try lexer.next_token();
    try testing.expectEqual(token.TokenType.LET, t.type);
    t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.IDENT, t.type);
    t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.ASSIGN, t.type);
    t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.INT, t.type);
}

test "lexer.assign" {
    const input = "=";
    var lexer = Lexer.new(input);
    try testing.expectEqual(lexer.ch, '=');
}

test "lexer.small_test" {
    const input = "let five = 5;";
    var lexer = Lexer.new(input);
    var t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.LET, t.type);
}

test "lexer.two_char_token" {
    const input = "10 == 10";
    var lexer = Lexer.new(input);
    _ = try lexer.next_token();
    const t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.EQ, t.type);
}

test "lexer.keyword" {
    const input = "let add = fn(x, y) { x + y; };";
    var lexer = Lexer.new(input);
    var t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.LET, t.type);
    for (0..2) |_| {
        _ = try lexer.next_token();
    }
    t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.FUNCTION, t.type);
}

test "lexer.semicolon" {
    const input = "10 == 10;";
    var lexer = Lexer.new(input);
    for (0..3) |_| {
        _ = try lexer.next_token();
    }
    const t = try lexer.next_token();
    try testing.expectEqual(token.TokenType.SEMICOLON, t.type);
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
    const correct_types: [73]token.TokenType = .{
        token.TokenType.LET,
        token.TokenType.IDENT,
        token.TokenType.ASSIGN,
        token.TokenType.INT,
        token.TokenType.SEMICOLON,
        token.TokenType.LET,
        token.TokenType.IDENT,
        token.TokenType.ASSIGN,
        token.TokenType.INT,
        token.TokenType.SEMICOLON,
        token.TokenType.LET,
        token.TokenType.IDENT,
        token.TokenType.ASSIGN,
        token.TokenType.FUNCTION,
        token.TokenType.LPAREN,
        token.TokenType.IDENT,
        token.TokenType.COMMA,
        token.TokenType.IDENT,
        token.TokenType.RPAREN,
        token.TokenType.LSQUIRLY,
        token.TokenType.IDENT,
        token.TokenType.PLUS,
        token.TokenType.IDENT,
        token.TokenType.SEMICOLON,
        token.TokenType.RSQUIRLY,
        token.TokenType.SEMICOLON,
        token.TokenType.LET,
        token.TokenType.IDENT,
        token.TokenType.ASSIGN,
        token.TokenType.IDENT,
        token.TokenType.LPAREN,
        token.TokenType.IDENT,
        token.TokenType.COMMA,
        token.TokenType.IDENT,
        token.TokenType.RPAREN,
        token.TokenType.SEMICOLON,
        token.TokenType.BANG,
        token.TokenType.MINUS,
        token.TokenType.SLASH,
        token.TokenType.ASTERISK,
        token.TokenType.INT,
        token.TokenType.SEMICOLON,
        token.TokenType.INT,
        token.TokenType.LT,
        token.TokenType.INT,
        token.TokenType.GT,
        token.TokenType.INT,
        token.TokenType.IF,
        token.TokenType.LPAREN,
        token.TokenType.INT,
        token.TokenType.LT,
        token.TokenType.INT,
        token.TokenType.RPAREN,
        token.TokenType.LSQUIRLY,
        token.TokenType.RETURN,
        token.TokenType.TRUE,
        token.TokenType.SEMICOLON,
        token.TokenType.RSQUIRLY,
        token.TokenType.ELSE,
        token.TokenType.LSQUIRLY,
        token.TokenType.RETURN,
        token.TokenType.FALSE,
        token.TokenType.SEMICOLON,
        token.TokenType.RSQUIRLY,
        token.TokenType.INT,
        token.TokenType.EQ,
        token.TokenType.INT,
        token.TokenType.SEMICOLON,
        token.TokenType.INT,
        token.TokenType.NEQ,
        token.TokenType.INT,
        token.TokenType.SEMICOLON,
        token.TokenType.EOF,
    };
    var lexer = Lexer.new(input);
    for (correct_types, 0..) |correct_type, i| {
        var t = try lexer.next_token();
        try testing.expectEqual(correct_type, t.type);
        std.debug.print("pass {}\n", .{i});
    }
}
