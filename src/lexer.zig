const token = @import("token.zig");
const Token = token.Token;

fn is_digit(d: u8) bool {
    return '0' <= d and '9' >= d;
}

fn is_alphabetic(c: u8) bool {
    return ('a' <= c and 'z' >= c) or ('A' <= c and 'Z' >= c);
}

const Lexer = struct {
    const Self = @This();

    input: []const u8,
    position: usize,
    read_position: usize,
    ch: u8,

    pub fn new(input: []const u8) Self {
        return .{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0,
        };
    }

    pub fn read_char(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }
        self.position = self.read_position;
        self.read_position += 1;
    }

    fn read_identifier(self: *Self) []const u8 {
        var pos = self.position;
        while (is_alphabetic(self.ch) or self.ch == '_') {
            self.read_char();
        }
        return self.input[pos..self.position];
    }

    fn read_number(self: *Self) []const u8 {
        var pos = self.position;
        while (is_digit(self.ch)) {
            self.read_char();
        }
        return self.input[pos..self.position];
    }

    pub fn next_token(self: *Self) Token {
        while (self.ch == ' ' or self.ch == '\t') {
            self.read_char();
        }

        const tokType = switch (self.ch) {
            '=' => token.TokenType.ASSIGN,
            ';' => token.TokenType.SEMICOLON,
            '(' => token.TokenType.LPAREN,
            ')' => token.TokenType.RPAREN,
            '{' => token.TokenType.LSQUIRLY,
            '}' => token.TokenType.RSQUIRLY,
            '+' => token.TokenType.PLUS,
            ',' => token.TokenType.COMMA,
            else => {
                if (is_alphabetic(self.ch) or self.ch == '_') {
                    var literal = self.read_identifier();
                    return token.lookup_ident(literal);
                }
                if (is_digit(self.ch)) {
                    var literal = self.read_number();
                    return Token{
                        .type = token.TokenType.INT,
                        .literal = literal,
                    };
                }
                return token.TokenType.ILLEGAL;
            },
        };

        self.read_char();
        return .{
            .type = tokType,
            .literal = self.ch,
        };
    }
};
