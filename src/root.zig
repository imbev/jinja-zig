const std = @import("std");
const testing = std.testing;
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Token = @import("lexer.zig").Token;

pub fn eval_file(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    return _eval_file(allocator, path, false);
}

pub fn eval(allocator: std.mem.Allocator, content: []const u8) !u8 {
    return _eval(allocator, content, false);
}

fn _eval_file(allocator: std.mem.Allocator, path: []const u8, debug: bool) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const content = try file.reader().readAllAlloc(allocator, std.math.maxInt(usize));

    return try _eval(allocator, content, debug);
}

fn _eval(allocator: std.mem.Allocator, content: []const u8, debug: bool) ![]const u8 {
    var lexer = Lexer.init(content, "none");
    var tokens = std.ArrayList(Token).init(allocator);
    while (lexer.has_next()) {
        try tokens.append(lexer.next());
    }

    var parser = Parser.init(allocator);
    const final = try parser.parse(tokens);

    if (debug) {
        std.debug.print("\n==== Template ====\n", .{});
        for (tokens.items) |token| {
            token.log();
        }
        std.debug.print("=========\n", .{});
    }

    return final;
}

test "1" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/1.jinja", false);
    try testing.expectEqualStrings("<html>\n</html>", source);
}

test "2" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/2.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\n</body>\n</html>", source);
}

test "3" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/3.jinja", false);
    try testing.expectEqualStrings("<html>\n\n</html>", source);
}

test "4" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/4.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\nhello\n</body>\n</html>", source);
}

test "5" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/5.jinja", false);
    try testing.expectEqualStrings("<html>\n<body>\nworld\n</body>\n</html>", source);
}

test "6" {
    const allocator = std.heap.page_allocator;
    const source = try _eval_file(allocator, "test/6.jinja", false);
    try testing.expectEqualStrings("<html>\n\n</html>", source);
}

// test "7" {
//     const allocator = std.heap.page_allocator;
//     const source = try _eval_file(allocator, "test/7.jinja", true);
//     try testing.expectEqualStrings("<div>\n\nyay\n\n</div>", source);
// }
