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
                    switch (tokens.items[i + 1].kind) {
                        TokenKind.HASH => {
                            i += 2;
                            while (tokens.items[i].kind != TokenKind.HASH and tokens.items[i + 1].kind != TokenKind.CLOSE_BRACE) {
                                i += 1;
                            }
                            i += 1;
                        },
                        TokenKind.OPEN_BRACE => {
                            i += 4;
                            while (tokens.items[i + 1].kind != TokenKind.CLOSE_BRACE and tokens.items[i + 2].kind != TokenKind.CLOSE_BRACE) {
                                const new_out = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ out, tokens.items[i].content });
                                self.allocator.free(out);
                                out = new_out;
                                i += 1;
                            }
                            i += 3;
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
