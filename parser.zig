const std = @import("std");
const eql = std.mem.eql;
const Node = @import("node.zig").Node;
const testing = std.testing;

const ParserErrors = error{
    OutOfMemory,
};

var level: i16 = 0;

pub const Parser = struct {
    index: usize = 0,
    binary_operators: [][]const u8,
    brackets: [][]const u8,
    tokens: std.mem.SplitIterator(u8, .scalar),
    next_token: ?[]const u8 = null,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, text: []const u8, operators: [][]const u8, brackets: ?[][]const u8) !Parser {
        const tokens: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, text, ' ');
        const parser_brackets: [][]const u8 = brackets orelse &.{};
        return .{ .tokens = tokens, .binary_operators = operators, .allocator = allocator, .brackets = parser_brackets };
    }

    pub fn getPrecedence(self: *Parser, token: []const u8) usize {
        for (self.binary_operators, 0..) |operator, i| {
            if (operator.len != token.len) continue;
            if (eql(u8, operator, token)) return i + 1;
        }
        return 0;
    }

    pub fn isBinaryOperator(self: *Parser, token: []const u8) bool {
        return self.getPrecedence(token) > 0;
    }

    fn getNextToken(self: *Parser) []const u8 {
        if (self.next_token) |token| {
            const t = token;
            self.next_token = null;
            return t;
        }
        return self.tokens.next() orelse "_";
    }

    fn backup(self: *Parser, token: []const u8) void {
        self.next_token = token;
    }

    fn isOpenBracket(self: *Parser) bool {
        const next = self.getNextToken();
        const result = next.len > 0 and next[0] == '(';
        if (!result) {
            self.backup(next);
            return result;
        }
        return result;
    }

    fn isCloseBracket(self: *Parser) bool {
        const next = self.getNextToken();
        const result = next.len > 0 and next[0] == ')';
        if (!result) {
            self.backup(next);
            return result;
        }
        return result;
    }

    fn parseIncreasingPrecedence(self: *Parser, left: *Node, min_prec: usize) ParserErrors!*Node {
        const next = self.getNextToken();
        if (!self.isBinaryOperator(next)) {
            self.backup(next);
            return left;
        }

        const next_prec = self.getPrecedence(next);
        if (next_prec <= min_prec) {
            self.backup(next);
            return left;
        }

        const right = try self.parseExpression(next_prec);
        return self.makeBinary(left, toOperator(next), right);
    }

    pub fn parseExpression(self: *Parser, min_prec: usize) ParserErrors!*Node {
        var left: *Node = undefined;
        if (self.isOpenBracket()) {
            left = try self.parseExpression(0);
        } else {
            left = try self.parseLeaf();
        }

        while (true) {
            const node = try self.parseIncreasingPrecedence(left, min_prec);
            if (node == left) {
                break;
            }
            left = node;

            if (self.isCloseBracket()) break;
        }
        return left;
    }

    fn makeBinary(self: *Parser, left: *Node, op: []const u8, right: *Node) !*Node {
        const node = try self.allocator.create(Node);
        node.* = Node{ .op = op, .left = left, .right = right };
        return @constCast(node);
    }

    fn parseLeaf(self: *Parser) !*Node {
        const node = try self.allocator.create(Node);
        const token = self.getNextToken();
        const node_value = if (self.isBinaryOperator(token)) toOperator(token) else token;
        node.* = Node{ .op = node_value };
        return node;
    }

    fn toOperator(str: []const u8) []const u8 {
        return str;
    }

    pub fn deinit(self: *Parser, node: *Node) void {
        if (node.left) |n| {
            self.deinit(n);
        }
        if (node.right) |n| {
            self.deinit(n);
        }
        self.allocator.destroy(node);
    }
};

pub fn print(node: ?*Node) void {
    if (node) |n| {
        if (n.isLeaf()) {
            std.debug.print("{s}", .{n.op});
            return;
        }
        std.debug.print("[", .{});
        print(n.left);
        std.debug.print("{s}", .{n.op});
        print(n.right);
        std.debug.print("]", .{});
    }
}

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
