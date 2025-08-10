const std = @import("std");
const Token = @import("lexer.zig").Token;
const TokenKind = @import("lexer.zig").TokenKind;
const Errors = @import("errors.zig");

const State = struct { cursor: usize, tokens: []const Token };

const PlainText = struct {
    content: []const u8,

    fn parse(allocator: std.mem.Allocator, state: *State) !?PlainText {
        var text: []u8 = "";

        while (state.cursor < state.tokens.len) {
            if (state.tokens[state.cursor].kind == TokenKind.OPEN_BRACE and state.tokens[state.cursor + 1].kind == TokenKind.HASH) {
                break;
            }

            if (state.tokens[state.cursor].kind == TokenKind.OPEN_BRACE and state.tokens[state.cursor + 1].kind == TokenKind.OPEN_BRACE) {
                break;
            }

            const new = try std.fmt.allocPrint(allocator, "{s}{s}", .{ text, state.tokens[state.cursor].content });
            allocator.free(text);
            text = new;
            state.cursor += 1;
        }

        return PlainText{ .content = text };
    }

    fn eval(self: *const PlainText) []const u8 {
        return self.content;
    }

    fn debug(self: *const PlainText) void {
        std.debug.print("Plaintext (\n", .{});
        std.debug.print("{s}\n", .{self.content});
        std.debug.print(")\n", .{});
    }
};

const Comment = struct {
    fn parse(state: *State) !?Comment {
        var cursor = state.cursor;

        if (state.tokens[cursor].kind != TokenKind.OPEN_BRACE) {
            return null;
        }
        cursor += 1;

        if (state.tokens[cursor].kind != TokenKind.HASH) {
            return null;
        }
        cursor += 1;

        while (state.tokens[cursor].kind != TokenKind.HASH) {
            cursor += 1;
            if (cursor >= state.tokens.len) {
                std.debug.print("Error: Opened comments must be closed or escaped\n", .{});
                return Errors.SyntaxError.CommentNotClosed;
            }
        }
        cursor += 1;

        if (state.tokens[cursor].kind != TokenKind.CLOSE_BRACE) {
            std.debug.print("Error: Opened comments must be closed or escaped\n", .{});
            return Errors.SyntaxError.CommentNotClosed;
        }
        cursor += 1;
        state.cursor = cursor;
        return Comment{};
    }

    fn eval(self: *const Comment) []const u8 {
        _ = self;
        return "";
    }

    fn debug(self: *const Comment) void {
        _ = self;
        std.debug.print("Comment ()\n", .{});
    }
};

const String = struct {
    allocator: std.mem.Allocator,
    tokens: []const Token,

    pub fn parse(allocator: std.mem.Allocator, state: *State) ?String {
        var cursor = state.cursor;

        cursor += 1; // open brace
        cursor += 1; // open brace
        cursor += 1; // space

        if (state.tokens[cursor].kind != TokenKind.QUOTE and state.tokens[cursor].kind != TokenKind.DOUBLE_QUOTE) {
            return null;
        }
        const quote_kind = state.tokens[cursor].kind;
        cursor += 1;

        const start_index = cursor;
        while (state.tokens[cursor].kind != quote_kind) {
            cursor += 1;
        }

        if (state.tokens[cursor].kind != quote_kind) {
            return null;
        }
        cursor += 1;

        state.cursor = cursor;
        return String { .allocator = allocator, .tokens = state.tokens[start_index..state.cursor-1] };
    }

    pub fn eval(self: String) ![]const u8 {
        var out: []u8 = "";

        for (self.tokens) |token| {
            out = try std.mem.concat(self.allocator, u8, &[_][]const u8{ out, token.content });
        }

        return self.allocator.dupe(u8, out);
    }
};

const Integer = struct {
    allocator: std.mem.Allocator,
    value: isize,

    pub fn parse(allocator: std.mem.Allocator, state: *State) ?Integer {
        var cursor = state.cursor;

        cursor += 1; // open brace
        cursor += 1; // open brace
        cursor += 1; // space

        if (state.tokens[cursor].kind != TokenKind.INTEGER) {
            return null;
        }
        const value = std.fmt.parseInt(isize, state.tokens[cursor].content, 10) catch unreachable;
        cursor += 1;

        state.cursor = cursor;
        return Integer { .allocator = allocator, .value = value };
    }

    pub fn eval(self: Integer) ![]const u8 {
        return try std.fmt.allocPrint(self.allocator, "{d}", .{self.value});
    }
};

const ExpressionKind = union(enum) { string: String, integer: Integer };

const Expression = struct {
    allocator: std.mem.Allocator,
    start_index: usize,
    end_index: usize,
    tokens: []const Token,
    kind: ExpressionKind,

    fn parse(allocator: std.mem.Allocator, state: *State) !?Expression {
        var expression_kind: ?ExpressionKind = null;
        const start_index = state.cursor;
        var cursor = state.cursor;

        if (state.tokens[cursor].kind != TokenKind.OPEN_BRACE) {
            return null;
        }
        cursor += 1;

        if (state.tokens[cursor].kind != TokenKind.OPEN_BRACE) {
            return null;
        }
        cursor += 1;

        if (String.parse(allocator, state)) |string| {
            expression_kind = ExpressionKind{ .string = string };
            cursor = state.cursor;
        } else if (Integer.parse(allocator, state)) |integer| {
            expression_kind = ExpressionKind{ .integer = integer };
            cursor = state.cursor;
        } else {
            state.tokens[cursor].log();
            @panic("Unimplemented");
        }

        cursor += 1; // space

        if (state.tokens[cursor].kind != TokenKind.CLOSE_BRACE) {
            std.debug.print("Error: Opened expressions must be closed or escaped\n", .{});
            return Errors.SyntaxError.ExpressionNotClosed;
        }
        cursor += 1;

        if (state.tokens[cursor].kind != TokenKind.CLOSE_BRACE) {
            std.debug.print("Error: Opened expressions must be closed or escaped\n", .{});
            return Errors.SyntaxError.ExpressionNotClosed;
        }
        cursor += 1;

        state.cursor = cursor;
        return Expression{ .allocator = allocator, .start_index = start_index, .end_index = state.cursor - 1, .tokens = state.tokens[start_index..state.cursor], .kind = expression_kind.? };
    }

    fn eval(self: *const Expression) ![]const u8 {
        switch (self.kind) {
            .string => |string| {
                return string.eval();
            },
            .integer => |integer| {
                return integer.eval();
            }
        }
    }

    fn debug(self: *const Expression) void {
        std.debug.print("Expression (\n", .{});
        std.debug.print("Start index: {d}\nEnd index: {d}\n", .{ self.start_index, self.end_index });
        std.debug.print(")\n", .{});
    }
};

const TagKind = union(enum) { plaintext: PlainText, comment: Comment, expression: Expression };

const Tag = struct {
    kind: TagKind,

    fn parse(allocator: std.mem.Allocator, state: *State) !?Tag {
        while (state.cursor < state.tokens.len) {
            if (try Comment.parse(state)) |comment| {
                return Tag{ .kind = TagKind{ .comment = comment } };
            }

            if (try Expression.parse(allocator, state)) |expression| {
                return Tag{ .kind = TagKind{ .expression = expression } };
            }

            if (try PlainText.parse(allocator, state)) |plaintext| {
                return Tag{ .kind = TagKind{ .plaintext = plaintext } };
            }

            std.debug.print("Error: Unable to parse tag\n", .{});
            return Errors.SyntaxError.TagNotParsable;
        }

        return null;
    }

    fn eval(self: *const Tag) ![]const u8 {
        switch (self.kind) {
            .plaintext => |*plaintext| {
                return plaintext.eval();
            },
            .comment => |*comment| {
                return comment.eval();
            },
            .expression => |*expression| {
                return try expression.eval();
            },
        }
    }

    fn debug(self: *const Tag) void {
        std.debug.print("Tag (\n", .{});
        switch (self.kind) {
            .plaintext => |*plaintext| {
                plaintext.debug();
            },
            .comment => |*comment| {
                comment.debug();
            },
            .expression => |*expression| {
                expression.debug();
            },
        }
        std.debug.print(")\n", .{});
    }
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    tags: std.ArrayList(Tag),

    pub fn parse(allocator: std.mem.Allocator, tokens: []const Token) !?Parser {
        var tags = std.ArrayList(Tag).init(allocator);
        var state = State{
            .cursor = 0,
            .tokens = tokens,
        };
        while (state.cursor < state.tokens.len) {
            if (try Tag.parse(allocator, &state)) |tag| {
                try tags.append(tag);
            }
        }
        return Parser{ .allocator = allocator, .tags = tags };
    }

    pub fn eval(self: *const Parser) ![]const u8 {
        var out: []u8 = "";

        for (self.tags.items) |tag| {
            out = try std.mem.concat(self.allocator, u8, &[_][]const u8{ out, try tag.eval() });
        }

        return self.allocator.dupe(u8, out);
    }

    pub fn debug(self: *const Parser) void {
        std.debug.print("Template (\n", .{});
        for (self.tags.items) |tag| {
            tag.debug();
        }
        std.debug.print(")\n", .{});
    }
};

pub fn parse(allocator: std.mem.Allocator, tokens: std.ArrayList(Token)) !Parser {
    return try Parser.parse(allocator, tokens.items) orelse @panic("Unable to parse template: Parse Error");
}
