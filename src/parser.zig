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

const Expression = struct {
    allocator: std.mem.Allocator,
    start_index: usize,
    end_index: usize,
    tokens: []const Token,

    fn parse(allocator: std.mem.Allocator, state: *State) !?Expression {
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

        while (state.tokens[cursor].kind != TokenKind.CLOSE_BRACE) {
            cursor += 1;
            if (cursor >= state.tokens.len) {
                std.debug.print("Error: Opened expressions must be closed or escaped\n", .{});
                return Errors.SyntaxError.ExpressionNotClosed;
            }
        }
        cursor += 1;

        if (state.tokens[cursor].kind != TokenKind.CLOSE_BRACE) {
            std.debug.print("Error: Opened expressions must be closed or escaped\n", .{});
            return Errors.SyntaxError.ExpressionNotClosed;
        }
        cursor += 1;

        state.cursor = cursor;
        return Expression{ .allocator = allocator, .start_index = start_index, .end_index = state.cursor - 1, .tokens = state.tokens[start_index..state.cursor] };
    }

    fn eval(self: *const Expression) ![]const u8 {
        var out: []u8 = "";

        for (0..self.tokens.len) |i| {
            if (i < 4 or i >= self.tokens.len - 4) {
                continue;
            }
            out = try std.mem.concat(self.allocator, u8, &[_][]const u8{ out, self.tokens[i].content });
        }

        return self.allocator.dupe(u8, out);
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
