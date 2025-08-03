const std = @import("std");

pub const TokenKind = enum { CHAR, OPEN_BRACE, CLOSE_BRACE, PERCENT, HASH, QUOTE, DOUBLE_QUOTE, FOR, IN, VARIABLE, SPACE, EOF };

pub const Token = struct {
    kind: TokenKind,
    content: []const u8,

    fn init(kind: TokenKind, content: []const u8) Token {
        return Token{
            .kind = kind,
            .content = content,
        };
    }

    pub fn log(self: *const Token) void {
        var repr = self.content;
        if (std.mem.eql(u8, "\n", repr)) {
            repr = "newline";
        }
        std.debug.print("(token {s} \"{s}\")\n", .{ @tagName(self.kind), repr });
    }
};

pub const Lexer = struct {
    content: []const u8,
    path: []const u8,
    cursor: usize,

    pub fn init(content: []const u8, path: []const u8) Lexer {
        return Lexer{
            .content = content,
            .path = path,
            .cursor = 0,
        };
    }

    pub fn has_next(self: *const Lexer) bool {
        return self.cursor < self.content.len;
    }

    fn expect(self: *const Lexer, expected: []const u8) bool {
        if (self.cursor + expected.len < self.content.len) {
            if (std.mem.eql(u8, self.content[self.cursor + 1 .. self.cursor + expected.len], expected[0 .. expected.len - 1])) {
                return true;
            }
        }
        return false;
    }

    fn starts_with(self: *const Lexer, prefix: []const u8) bool {
        if (self.content.len < self.cursor + prefix.len) {
            return false;
        }
        return std.mem.startsWith(u8, self.content[self.cursor .. self.cursor + prefix.len], prefix[0..prefix.len]);
    }

    fn followed_by_alphabetic(self: *const Lexer) bool {
        if (self.cursor + 1 >= self.content.len) {
            return false;
        }
        return std.ascii.isAlphabetic(self.content[self.cursor + 1]);
    }

    fn peek(self: *Lexer) u8 {
        return self.content[self.cursor];
    }

    pub fn next(self: *Lexer) Token {
        if (!self.has_next()) {
            return Token.init(TokenKind.EOF, "EOF");
        }

        switch (self.peek()) {
            '{' => {
                self.cursor += 1;
                return Token.init(TokenKind.OPEN_BRACE, "{");
            },
            '}' => {
                self.cursor += 1;
                return Token.init(TokenKind.CLOSE_BRACE, "}");
            },
            '#' => {
                self.cursor += 1;
                return Token.init(TokenKind.HASH, "#");
            },
            '\'' => {
                self.cursor += 1;
                return Token.init(TokenKind.QUOTE, "'");
            },
            else => {
                self.cursor += 1;
                return Token.init(TokenKind.CHAR, self.content[self.cursor - 1 .. self.cursor]);
            },
        }
    }
};

pub fn main() void {
    const content = "<html>{{ \"hello\" }} {{ variable }} {% for myvar in mylist %} {# content #} </html>";

    var lexer = Lexer.init(content, "none");

    while (lexer.has_next()) {
        var next = lexer.next();
        next.log();
    }

    return;
}
