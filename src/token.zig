const std = @import("std");

pub const Token = union(enum) {
    IDENT: []const u8,
    INT: []const u8,

    ILLEGAL,
    EOF,
    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LSQUIRLY,
    RSQUIRLY,
    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,

    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,

    LT,
    GT,
    EQ,
    NEQ,
};

const keywords = std.ComptimeStringMap(Token, .{
    .{ "fn", .FUNCTION },
    .{ "let", .LET },
    .{ "true", .TRUE },
    .{ "false", .FALSE },
    .{ "if", .IF },
    .{ "else", .ELSE },
    .{ "return", .RETURN },
});

pub fn lookup_ident(literal: []const u8) Token {
    const tok = keywords.get(literal);
    if (tok == null) {
        return Token{ .IDENT = literal };
    }
    return tok.?;
}

pub fn get_literal(t: Token) []const u8 {
    return switch (t) {
        .IDENT => t.IDENT,
        .INT => t.INT,

        .ILLEGAL => "",
        .EOF => "",
        .COMMA => ",",
        .SEMICOLON => ";",
        .LPAREN => "(",
        .RPAREN => ")",
        .LSQUIRLY => "{",
        .RSQUIRLY => "}",
        .FUNCTION => "fn",
        .LET => "let",
        .TRUE => "true",
        .FALSE => "false",
        .IF => "if",
        .ELSE => "else",
        .RETURN => "return",

        .ASSIGN => "=",
        .PLUS => "+",
        .MINUS => "-",
        .BANG => "!",
        .ASTERISK => "*",
        .SLASH => "/",

        .LT => "<",
        .GT => ">",
        .EQ => "==",
        .NEQ => "!=",
    };
}

pub fn get_type_str(t: Token) []const u8 {
    return switch (t) {
        .IDENT => "IDENT",
        .INT => "INT",

        .ILLEGAL => "ILLEGAL",
        .EOF => "EOF",
        .COMMA => "COMMA",
        .SEMICOLON => "SEMICOLON",
        .LPAREN => "LPAREN",
        .RPAREN => "RPAREN",
        .LSQUIRLY => "LSQUIRlY",
        .RSQUIRLY => "RSQUIRLy",
        .FUNCTION => "FUNCTION",
        .LET => "LET",
        .TRUE => "TRUE",
        .FALSE => "FALSE",
        .IF => "IF",
        .ELSE => "ELSE",
        .RETURN => "RETURN",

        .ASSIGN => "ASSIGN",
        .PLUS => "PLUS",
        .MINUS => "MINUS",
        .BANG => "BANG",
        .ASTERISK => "ASTERISK",
        .SLASH => "SLASH",

        .LT => "LT",
        .GT => "GT",
        .EQ => "EQ",
        .NEQ => "NEQ",
    };
}

test "lookup_ident" {
    var t: Token = lookup_ident("let");
    try std.testing.expectEqual(t, Token.LET);

    t = lookup_ident("five");
    try std.testing.expectEqual(t, Token{ .IDENT = "five" });

    t = lookup_ident("fn");
    try std.testing.expectEqual(t, Token.FUNCTION);
}
