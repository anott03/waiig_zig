const std = @import("std");

pub const TokenType = enum {
    ILLEGAL,
    EOF,
    IDENT,
    INT,
    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LSQUIRLY,
    RSQUIRLY,
    FUNCTION,
    LET,

    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,

    LT,
    GT,
};

pub const Token = struct {
    type: TokenType,
    literal: []const u8,
};

const HashMap = std.StringHashMap(TokenType);
pub fn lookup_ident(literal: []const u8) !TokenType {
    var keywords: HashMap = HashMap.init(std.heap.page_allocator);
    try keywords.put("fn", TokenType.FUNCTION);
    try keywords.put("let", TokenType.LET);

    const tok = keywords.get(literal);
    if (tok == null) {
        return TokenType.IDENT;
    }
    return tok.?;
}

test "lookup_ident" {
    var t: TokenType = try lookup_ident("let");
    try std.testing.expectEqual(t, TokenType.LET);

    t = try lookup_ident("five");
    try std.testing.expectEqual(t, TokenType.IDENT);

    t = try lookup_ident("fn");
    try std.testing.expectEqual(t, TokenType.FUNCTION);
}
