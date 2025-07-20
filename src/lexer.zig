const std = @import("std");

pub const TokenKind = enum {
    STRING,
    OPEN_BRACE,
    CLOSE_BRACE,
    PERCENT,
    HASH,
    QUOTE,
    DOUBLE_QUOTE,
    FOR,
    IN,
    VARIABLE,
    SPACE,
};

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

const Literals: [6]Token = .{
    Token.init(TokenKind.OPEN_BRACE, "{"),
    Token.init(TokenKind.CLOSE_BRACE, "}"),
    Token.init(TokenKind.PERCENT, "%"),
    Token.init(TokenKind.HASH, "#"),
    Token.init(TokenKind.QUOTE, "'"),
    Token.init(TokenKind.DOUBLE_QUOTE, "\""),
};

const Keywords: [2]Token = .{
    Token.init(TokenKind.FOR, "for"),
    Token.init(TokenKind.IN, "in"),
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

    pub fn next(self: *Lexer) Token {
        var content: []const u8 = "";
        var kind = TokenKind.STRING;

        for (Literals) |literal| {
            if (self.starts_with(literal.content)) {
                kind = literal.kind;
                content = literal.content;
                self.cursor += literal.content.len;
                return Token.init(kind, content);
            }
        }

        if (self.starts_with(" ")) {
            if (!self.followed_by_alphabetic()) {
                content = self.content[self.cursor .. self.cursor + 1];
                self.cursor += 1;
                kind = TokenKind.SPACE;
                return Token.init(kind, content);
            }
            var cursor2 = self.cursor + 1;
            while (self.content[cursor2] != ' ') {
                cursor2 += 1;
                if (cursor2 >= self.content.len) {
                    content = self.content[self.cursor .. self.cursor + 1];
                    self.cursor += 1;
                    return Token.init(kind, content);
                }
            }
            kind = TokenKind.VARIABLE;
            content = self.content[self.cursor + 1 .. cursor2];
            self.cursor = cursor2;

            for (Keywords) |keyword| {
                if (std.mem.eql(u8, content, keyword.content)) {
                    return keyword;
                }
            }

            return Token.init(kind, content);
        }

        content = self.content[self.cursor .. self.cursor + 1];

        self.cursor += 1;
        return Token.init(kind, content);
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
