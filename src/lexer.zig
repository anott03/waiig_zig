const std = @import("std");
const token = @import("token.zig");
const Token = token.Token;

fn is_digit(d: u8) bool {
    return std.ascii.isDigit(d);
}

fn is_alphabetic(c: u8) bool {
    return std.ascii.isAlphabetic(c);
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

    pub fn next_token(self: *Self) Token {
        while (is_whitespace(self.ch)) {
            self.read_char();
        }

        defer self.read_char();
        return switch (self.ch) {
            '=' => blk: {
                if (self.peek_char() == '=') {
                    self.read_char();
                    break :blk .EQ;
                } else {
                    break :blk .ASSIGN;
                }
            },
            '+' => .PLUS,
            '-' => .MINUS,
            '!' => blk: {
                if (self.peek_char() == '=') {
                    self.read_char();
                    break :blk .NEQ;
                } else {
                    break :blk .BANG;
                }
            },
            '*' => .ASTERISK,
            '/' => .SLASH,
            '<' => .LT,
            '>' => .GT,
            ';' => .SEMICOLON,
            '(' => .LPAREN,
            ')' => .RPAREN,
            '{' => .LSQUIRLY,
            '}' => .RSQUIRLY,
            ',' => .COMMA,
            0 => .EOF,
            'a'...'z', 'A'...'Z', '_' => blk: {
                const literal = self.read_identifier();
                break :blk token.lookup_ident(literal);
            },
            '0'...'9' => blk: {
                var literal = self.read_number();
                break :blk .{ .INT = literal };
            },
            else => .ILLEGAL,
        };
    }
};
