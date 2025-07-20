const std = @import("std");
const Token = @import("lexer.zig").Token;
const TokenKind = @import("lexer.zig").TokenKind;

pub const Parser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return Parser{ .allocator = allocator };
    }

    pub fn parse(self: *Parser, tokens: std.ArrayList(Token)) ![]const u8 {
        var i: usize = 0;
        var out: []const u8 = "";
        while (i < tokens.items.len) {
            switch (tokens.items[i].kind) {
                TokenKind.OPEN_BRACE => {
                    var j = i + 1;
                    switch (tokens.items[j].kind) {
                        TokenKind.HASH => {
                            while (!(tokens.items[j].kind == TokenKind.HASH and tokens.items[j + 1].kind == TokenKind.CLOSE_BRACE)) {
                                j += 1;
                            }
                            i = j + 1;
                        },
                        TokenKind.OPEN_BRACE => {
                            if (tokens.items[j + 1].kind == TokenKind.SPACE and (tokens.items[j + 2].kind == TokenKind.DOUBLE_QUOTE or tokens.items[j + 2].kind == TokenKind.QUOTE)) {
                                var k = j + 3;
                                while (tokens.items[k].kind == TokenKind.STRING) {
                                    const new_out = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ out, tokens.items[k].content });
                                    self.allocator.free(out);
                                    out = new_out;
                                    k += 1;
                                }
                                i = k + 3;
                            } else {
                                @panic("unimplemented");
                            }
                        },
                        else => {
                            const new_out = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ out, tokens.items[i].content });
                            self.allocator.free(out);
                            out = new_out;
                        },
                    }
                },

                else => {
                    const new_out = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ out, tokens.items[i].content });
                    self.allocator.free(out);
                    out = new_out;
                },
            }

            i += 1;
        }
        return out;
    }
};
