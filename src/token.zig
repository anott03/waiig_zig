const std = @import("std");

pub const Token = union(enum) {
    ILLEGAL,
    EOF,
    IDENT: []const u8,
    INT: []const u8,
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

// pub const Token = struct {
//     type: TokenType,
//     literal: []const u8,
// };

const HashMap = std.StringHashMap(Token);
pub fn lookup_ident(literal: []const u8) !Token {
    var keywords: HashMap = HashMap.init(std.heap.page_allocator);
    try keywords.put("fn", Token.FUNCTION);
    try keywords.put("let", Token.LET);
    try keywords.put("true", Token.TRUE);
    try keywords.put("false", Token.FALSE);
    try keywords.put("if", Token.IF);
    try keywords.put("else", Token.ELSE);
    try keywords.put("return", Token.RETURN);

    const tok = keywords.get(literal);
    if (tok == null) {
        return Token{ .IDENT = literal };
    }
    return tok.?;
}

test "lookup_ident" {
    var t: Token = try lookup_ident("let");
    try std.testing.expectEqual(t, Token.LET);

    t = try lookup_ident("five");
    try std.testing.expectEqual(t, Token{ .IDENT = "five" });

    t = try lookup_ident("fn");
    try std.testing.expectEqual(t, Token.FUNCTION);
}
