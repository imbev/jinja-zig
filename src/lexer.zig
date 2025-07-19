const std = @import("std");
const Token = @import("token.zig");

allocator: std.mem.Allocator,
source: []const u8,

pub fn lex(self: *@This()) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(self.allocator);

    var pass_one = std.ArrayList(Token).init(self.allocator);
    defer pass_one.deinit();

    for (self.source) |letter| {
        try pass_one.append(switch (letter) {
            '\\' => Token{ .token_type = Token.TokenType.BACKSLASH, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '{' => Token{ .token_type = Token.TokenType.LBRACE, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '}' => Token{ .token_type = Token.TokenType.RBRACE, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '#' => Token{ .token_type = Token.TokenType.NUMBER_SIGN, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '%' => Token{ .token_type = Token.TokenType.PERCENT, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '\'' => Token{ .token_type = Token.TokenType.QUOTE, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            '"' => Token{ .token_type = Token.TokenType.DOUBLE_QUOTE, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
            else => Token{ .token_type = Token.TokenType.OTHER, .source = try std.fmt.allocPrint(self.allocator, "{c}", .{letter}) },
        });
    }

    var pass_two = std.ArrayList(Token).init(self.allocator);
    defer pass_two.deinit();

    var i: usize = 0;
    while (i < pass_one.items.len) {
        if (pass_one.items[i].token_type == Token.TokenType.OTHER) {
            var cursor: usize = i + 1;
            while (cursor < pass_one.items.len and pass_one.items[cursor].token_type == Token.TokenType.OTHER) {
                cursor += 1;
            }
            var other_token_sources = std.ArrayList([]const u8).init(self.allocator);
            defer other_token_sources.deinit();
            var content: []u8 = "";
            for (pass_one.items[i..cursor]) |token| {
                const new_content = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ content, token.source });
                self.allocator.free(content);
                content = new_content;
            }
            i = cursor - 1;
            try pass_two.append(Token{ .token_type = Token.TokenType.OTHER, .source = content });
        } else if (pass_one.items[i].token_type == Token.TokenType.LBRACE) {
            try pass_two.append(switch (pass_one.items[i + 1].token_type) {
                Token.TokenType.LBRACE => Token{ .token_type = Token.TokenType.EXPRESSION_DELIM_START, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i].source, pass_one.items[i + 1].source }) },
                Token.TokenType.NUMBER_SIGN => Token{ .token_type = Token.TokenType.COMMENT_DELIM_START, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i].source, pass_one.items[i + 1].source }) },
                Token.TokenType.PERCENT => Token{ .token_type = Token.TokenType.STATEMENT_DELIM_START, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i].source, pass_one.items[i + 1].source }) },
                Token.TokenType.OTHER => Token{ .token_type = Token.TokenType.OTHER, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i].source, pass_one.items[i + 1].source }) },
                else => pass_one.items[i],
            });
            i += 1;
        } else if (pass_one.items[i].token_type == Token.TokenType.RBRACE) {
            switch (pass_one.items[i - 1].token_type) {
                Token.TokenType.RBRACE => {
                    _ = pass_two.pop();
                    try pass_two.append(Token{ .token_type = Token.TokenType.EXPRESSION_DELIM_END, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i - 1].source, pass_one.items[i].source }) });
                },
                Token.TokenType.NUMBER_SIGN => {
                    _ = pass_two.pop();
                    try pass_two.append(Token{ .token_type = Token.TokenType.COMMENT_DELIM_END, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i - 1].source, pass_one.items[i].source }) });
                },
                Token.TokenType.PERCENT => {
                    _ = pass_two.pop();
                    try pass_two.append(Token{ .token_type = Token.TokenType.STATEMENT_DELIM_END, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i - 1].source, pass_one.items[i].source }) });
                },
                Token.TokenType.OTHER => {
                    try pass_two.append(Token{ .token_type = Token.TokenType.OTHER, .source = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ pass_one.items[i - 1].source, pass_one.items[i].source }) });
                },
                else => try pass_two.append(pass_one.items[i]),
            }
        } else {
            try pass_two.append(pass_one.items[i]);
        }
        i += 1;
    }

    var pass_three = std.ArrayList(Token).init(self.allocator);
    defer pass_three.deinit();

    i = 0;
    while (i < pass_two.items.len) {
        if (pass_two.items[i].token_type == Token.TokenType.COMMENT_DELIM_START) {
            var cursor: usize = 0;
            while (cursor < pass_two.items.len) {
                if (pass_two.items[cursor].token_type == Token.TokenType.COMMENT_DELIM_END) {
                    var other_token_sources = std.ArrayList([]const u8).init(self.allocator);
                    defer other_token_sources.deinit();
                    var content: []u8 = "";
                    for (pass_two.items[i .. cursor + 1]) |token| {
                        const new_content = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ content, token.source });
                        self.allocator.free(content);
                        content = new_content;
                    }
                    try pass_three.append(Token{ .token_type = Token.TokenType.COMMENT, .source = content });
                    i = cursor + 1;
                    break;
                }
                cursor += 1;
            }
        }
        if (pass_two.items[i].token_type == Token.TokenType.EXPRESSION_DELIM_START) {
            var cursor: usize = 0;
            while (cursor < pass_two.items.len) {
                if (pass_two.items[cursor].token_type == Token.TokenType.EXPRESSION_DELIM_END) {
                    var other_token_sources = std.ArrayList([]const u8).init(self.allocator);
                    defer other_token_sources.deinit();
                    var content: []u8 = "";
                    for (pass_two.items[i .. cursor + 1]) |token| {
                        const new_content = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ content, token.source });
                        self.allocator.free(content);
                        content = new_content;
                    }
                    try pass_three.append(Token{ .token_type = Token.TokenType.EXPRESSION, .source = content });
                    i = cursor;
                    break;
                }
                cursor += 1;
            }
        } else {
            try pass_three.append(pass_two.items[i]);
        }
        i += 1;
    }

    for (pass_three.items) |token| {
        try tokens.append(token);
    }

    return tokens;
}
