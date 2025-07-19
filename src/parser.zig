const std = @import("std");
const Token = @import("token.zig");
const Lexer = @import("lexer.zig");

pub fn parse(allocator: std.mem.Allocator, tokens: std.ArrayList(Token)) ![]u8 {
    var out: []u8 = "";
    for (tokens.items) |token| {
        switch (token.token_type) {
            Token.TokenType.COMMENT => continue,
            Token.TokenType.EXPRESSION => {
                const new_out = try std.mem.concat(allocator, u8, &[_][]u8{ out, try parse_expression(allocator, token) });
                allocator.free(out);
                out = new_out;
            },
            else => {
                const new_out = try std.mem.concat(allocator, u8, &[_][]u8{ out, @constCast(token.source) });
                allocator.free(out);
                out = new_out;
            },
        }
    }
    return out;
}

fn parse_expression(
    allocator: std.mem.Allocator,
    token: Token,
) ![]u8 {
    var lexer = Lexer{ .allocator = allocator, .source = token.source[3 .. token.source.len - 3] };

    const pass_one = try lexer.lex();
    defer pass_one.deinit();

    var pass_two = std.ArrayList(Token).init(allocator);
    defer pass_two.deinit();

    var i: usize = 0;
    while (i < pass_one.items.len) {
        switch (pass_one.items[i].token_type) {
            Token.TokenType.DOUBLE_QUOTE => {
                var cursor: usize = i + 1;
                while (cursor < pass_one.items.len) {
                    if (pass_one.items[cursor].token_type == Token.TokenType.DOUBLE_QUOTE) {
                        var other_token_sources = std.ArrayList([]const u8).init(allocator);
                        defer other_token_sources.deinit();
                        var content: []u8 = "";
                        for (pass_one.items[i + 1 .. cursor]) |expression_token| {
                            const new_content = try std.fmt.allocPrint(allocator, "{s}{s}", .{ content, expression_token.source });
                            allocator.free(content);
                            content = new_content;
                        }
                        try pass_two.append(Token{ .token_type = Token.TokenType.OTHER, .source = content });
                        break;
                    }
                    cursor += 1;
                }
                i = cursor + 1;
            },
            Token.TokenType.QUOTE => {
                var cursor: usize = i + 1;
                while (cursor < pass_one.items.len) {
                    if (pass_one.items[cursor].token_type == Token.TokenType.QUOTE) {
                        var other_token_sources = std.ArrayList([]const u8).init(allocator);
                        defer other_token_sources.deinit();
                        var content: []u8 = "";
                        for (pass_one.items[i + 1 .. cursor]) |expression_token| {
                            const new_content = try std.fmt.allocPrint(allocator, "{s}{s}", .{ content, expression_token.source });
                            allocator.free(content);
                            content = new_content;
                        }
                        try pass_two.append(Token{ .token_type = Token.TokenType.OTHER, .source = content });
                        break;
                    }
                    cursor += 1;
                }
                i = cursor + 1;
            },
            else => {
                try pass_two.append(pass_one.items[i]);
            },
        }
        i += 1;
    }

    var content: []u8 = "";
    i = 0;
    for (pass_two.items[i..]) |expression_token| {
        const new_content = try std.fmt.allocPrint(allocator, "{s}{s}", .{ content, expression_token.source });
        allocator.free(content);
        content = new_content;
    }

    return content;
}
