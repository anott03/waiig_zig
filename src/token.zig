const std = @import("std");

const TokenType = union(enum) {
    ILLEGAL,
    EOF,
    IDENT,
    INT,
    ASSIGN,
    PLUS,
    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LSQUIRLY,
    RSQUIRLY,
    FUNCTION,
    LET,
};

const Token = struct {
    type: TokenType,
    literal: []const u8,
};

const HashMap = std.StringHashMap(TokenType);
pub fn lookup_ident(literal: []const u8) !Token {
    var keywords: HashMap = HashMap.init(std.heap.page_allocator);
    try keywords.put("fn", TokenType.FUNCTION);
    try keywords.put("let", TokenType.LET);

    const tok = keywords.get(literal);
    if (tok == null) {
        return .{ .type = TokenType.IDENT, .literal = literal };
    }
    return .{ .type = tok.?, .literal = literal };
}

test "lookup_ident" {
    var t: Token = try lookup_ident("let");
    try std.testing.expectEqual(t.type, TokenType.LET);

    t = try lookup_ident("five");
    try std.testing.expectEqual(t.type, TokenType.IDENT);

    t = try lookup_ident("fn");
    try std.testing.expectEqual(t.type, TokenType.FUNCTION);
}
