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
    defer tokens.deinit();

    while (lexer.has_next()) {
        try tokens.append(lexer.next());
    }

    var ast = try Parser.parse(allocator, tokens.items) orelse unreachable;
    defer ast.deinit();

    if (debug) {
        std.debug.print("\n==== Template ====\n", .{});
        for (tokens.items) |token| {
            token.log();
        }
        std.debug.print("=========\n", .{});
    }

    return try ast.eval();
}

fn test_eval(allocator: std.mem.Allocator, path: []const u8, debug: bool) !void {
    const source_path = try std.mem.concat(allocator, u8, &[_][]const u8{ path, "/test.jinja" });
    defer allocator.free(source_path);

    const source_file = try std.fs.cwd().openFile(source_path, .{});
    defer source_file.close();

    const source = try source_file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    const expected_path = try std.mem.concat(allocator, u8, &[_][]const u8{ path, "/test.html" });
    defer allocator.free(expected_path);

    const expected_file = try std.fs.cwd().openFile(expected_path, .{});
    defer expected_file.close();

    const expected = try expected_file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(expected);

    const actual = try _eval(allocator, source, debug);
    defer allocator.free(actual);

    try testing.expectEqualStrings(expected, actual);
}

test "comment_muli_line" {
    try test_eval(std.testing.allocator, "test/comment_multi_line", false);
}

test "comment_single_line" {
    try test_eval(std.testing.allocator, "test/comment_single_line", false);
}

test "expresssion_literal_integer" {
    try test_eval(std.testing.allocator, "test/expression_literal_integer", false);
}

test "expresssion_literal_string_double_quote" {
    try test_eval(std.testing.allocator, "test/expression_literal_string_double_quote", false);
}

test "expresssion_literal_string_quote" {
    try test_eval(std.testing.allocator, "test/expression_literal_string_quote", false);
}

test "plaintext" {
    try test_eval(std.testing.allocator, "test/plaintext", false);
}

// test {
//     const allocator = std.testing.page_allocator;

//     var lexer = Lexer.init("<html>{# 'my comment' #}hello {{ 'world' }}</html>", "none");

//     var tokens = std.ArrayList(Token).init(allocator);
//     while (lexer.has_next()) {
//         try tokens.append(lexer.next());
//     }

//     const ast = try Ast.parse(allocator, tokens);
//     std.debug.print("{s}\n", .{try ast.eval()});
//     @panic("");
// }
