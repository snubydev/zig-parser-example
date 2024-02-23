const std = @import("std");
const testing = std.testing;
const P = @import("parser.zig");
const Parser = P.Parser;
const print = P.print;

test "is_operator" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    var p = try Parser.init(testing.allocator, "", &operators, &brackets);
    for (operators) |op| {
        try testing.expect(p.isBinaryOperator(op));
    }
    try testing.expect(!p.isBinaryOperator("%"));
    try testing.expect(!p.isBinaryOperator("ab"));
    try testing.expectEqual(p.brackets.len, 1);
}

test "init parser" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 13 * 8 + 10";
    const expected = [_][]const u8{ "500", "+", "13", "*", "8", "+", "10" };
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);

    // assert tokens list
    var i: usize = 0;
    var t: ?[]const u8 = p.next_token;
    while (t) |token| : (i += 1) {
        try testing.expect(i <= expected.len);
        try testing.expectEqualStrings(expected[i], token);
        t = p.tokens.next();
    }
    try testing.expectEqual(p.brackets.len, 0);
}

test "get precedence" {
    var operators = [_][]const u8{ "+", "*" };
    var p = try Parser.init(testing.allocator, "", &operators, null);
    try testing.expectEqual(p.getPrecedence("+"), 1);
    try testing.expectEqual(p.getPrecedence("*"), 2);
}

test "parse expression 1" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 13 * 8 + 10";
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    print(head);
    std.debug.print("\n", .{});
}

test "parse expression 2" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 * 13 + 8 * 10";
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    print(head);
    std.debug.print("\n", .{});
}

test "init parser with brackets" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "500 * ( 8 + 10 )";
    const expected = [_][]const u8{ "500", "*", "(", "8", "+", "10", ")" };
    std.debug.print("\n[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);

    // assert initial state
    try testing.expect(p.next_token == null);

    // assert tokens list
    var i: usize = 0;
    while (true) : (i += 1) {
        const token = p.getNextToken();
        if (token.len < 1 or token[0] == '_') break;
        try testing.expect(i <= expected.len);
        try testing.expectEqualStrings(expected[i], token);
    }
}

test "parse exression with brackets 1" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "500 * ( 8 + 10 )";
    std.debug.print("\n[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);

    // assert
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    print(head);
    std.debug.print("\n", .{});
}

test "parse exression with brackets 2" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "( lenght1 + width2 ) * count";
    std.debug.print("\n[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);

    // assert
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    print(head);
    std.debug.print("\n", .{});
}

test "parse exression with brackets 3" {
    var operators = [_][]const u8{ "+", "-", "*", "/" };
    var brackets = [_][]const u8{"()"};
    const text = "( 500 + 8 ) * ( 10 + 2 ) - ( 3 + 6 * 9 ) / 2 - 3 * ( 1 + 1 )";
    std.debug.print("\n[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);

    // assert
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    print(head);
    std.debug.print("\n", .{});
}
