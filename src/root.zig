const std = @import("std");
const testing = std.testing;
const Lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const Token = @import("token.zig");

pub fn eval_file(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return _eval_file(allocator, path, false);
}

pub fn eval(allocator: std.mem.Allocator, content: []const u8) !u8 {
    return _eval(allocator, content, false);
}

fn _eval_file(allocator: std.mem.Allocator, path: []const u8, debug: bool) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.reader().readAllAlloc(allocator, std.math.maxInt(usize));

    return try _eval(allocator, content, debug);
}

fn _eval(allocator: std.mem.Allocator, content: []const u8, debug: bool) ![]u8 {
    var lexer = Lexer{ .allocator = allocator, .source = content };
    const tokens = try lexer.lex();
    const final = try Parser.parse(allocator, tokens);

    if (debug) {
        std.debug.print("==== Template ====\n", .{});
        for (tokens.items) |token| {
            std.debug.print("== {s} ==\n{s}\n=====\n", .{ @tagName(token.token_type), token.source });
        }
        std.debug.print("=========\n", .{});
    }

    return final;
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/1.jinja", false);
    try testing.expectEqualStrings("<html>\n</html>", source);
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/2.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\n</body>\n</html>", source);
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/3.jinja", false);
    try testing.expectEqualStrings("<html>\n\n</html>", source);
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/4.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\nhello\n</body>\n</html>", source);
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/5.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\nworld\n</body>\n</html>", source);
}

test {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/6.jinja", false);
    try testing.expectEqualStrings("<html>\n\n</html>", source);
}
