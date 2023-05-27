const std = @import("std");
const token = @import("token.zig");
const Token = token.Token;

fn is_digit(d: u8) bool {
    return '0' <= d and '9' >= d;
}

fn is_alphabetic(c: u8) bool {
    return ('a' <= c and 'z' >= c) or ('A' <= c and 'Z' >= c);
}

fn is_whitespace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n';
}

pub const Lexer = struct {
    const Self = @This();

    input: []const u8,
    position: usize,
    read_position: usize,
    ch: u8,

    pub fn new(input: []const u8) Self {
        var l = Lexer{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0,
        };
        l.read_char();
        return l;
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

    fn peek_char(self: *Self) u8 {
        if (self.read_position >= self.input.len) {
            return 0;
        }
        return self.input[self.read_position];
    }

    fn read_identifier(self: *Self) []const u8 {
        var pos = self.position;
        while (is_alphabetic(self.peek_char()) or self.peek_char() == '_') {
            self.read_char();
        }
        return self.input[pos..self.read_position];
    }

    fn read_number(self: *Self) []const u8 {
        var pos = self.position;
        while (is_digit(self.peek_char())) {
            self.read_char();
        }
        return self.input[pos..self.read_position];
    }

    pub fn next_token(self: *Self) !Token {
        while (is_whitespace(self.ch)) {
            self.read_char();
        }

        var literal: []const u8 = self.input[self.position..self.read_position];
        var tokType: token.TokenType = undefined;
        switch (self.ch) {
            '=' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    literal = "==";
                    tokType = token.TokenType.EQ;
                } else {
                    tokType = token.TokenType.ASSIGN;
                }
            },
            '+' => {
                tokType = token.TokenType.PLUS;
            },
            '-' => {
                tokType = token.TokenType.MINUS;
            },
            '!' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    literal = "!=";
                    tokType = token.TokenType.NEQ;
                } else {
                    tokType = token.TokenType.BANG;
                }
            },
            '*' => {
                tokType = token.TokenType.ASTERISK;
            },
            '/' => {
                tokType = token.TokenType.SLASH;
            },
            '<' => {
                tokType = token.TokenType.LT;
            },
            '>' => {
                tokType = token.TokenType.GT;
            },
            ';' => {
                tokType = token.TokenType.SEMICOLON;
            },
            '(' => {
                tokType = token.TokenType.LPAREN;
            },
            ')' => {
                tokType = token.TokenType.RPAREN;
            },
            '{' => {
                tokType = token.TokenType.LSQUIRLY;
            },
            '}' => {
                tokType = token.TokenType.RSQUIRLY;
            },
            ',' => {
                tokType = token.TokenType.COMMA;
            },
            0 => {
                literal = "";
                tokType = token.TokenType.EOF;
            },
            else => {
                if (is_alphabetic(self.ch)) {
                    literal = self.read_identifier();
                    tokType = token.lookup_ident(literal) catch token.TokenType.ILLEGAL;
                } else if (is_digit(self.ch)) {
                    literal = self.read_number();
                    tokType = token.TokenType.INT;
                } else {
                    tokType = token.TokenType.ILLEGAL;
                }
            },
        }

        self.read_char();
        return .{
            .type = tokType,
            .literal = literal,
        };
    }
};
