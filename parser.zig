const std = @import("std");
const eql = std.mem.eql;
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;
const testing = std.testing;

const ParserErrors = error{
    OutOfMemory,
};

pub const Parser = struct {
    index: usize = 0,
    binary_operators: [][]const u8,
    brackets: [][]const u8,
    tokens: std.mem.SplitIterator(u8, .scalar),
    next_token: []const u8 = "",
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, text: []const u8, operators: [][]const u8, brackets: ?[][]const u8) !Parser {
        const tokens: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, text, ' ');
        const next_token: []const u8 = "";
        const parser_brackets: [][]const u8 = brackets orelse &.{};
        var p: Parser = .{ .tokens = tokens, .binary_operators = operators, .allocator = allocator, .next_token = next_token, .brackets = parser_brackets };
        p.loadNextToken();
        return p;
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

    pub fn loadNextToken(self: *Parser) void {
        self.next_token = self.tokens.next() orelse "_";
    }

    fn isOpenBracket(next: []const u8) bool {
        return next.len > 0 and next[0] == '(';
    }

    fn isCloseBracket(next: []const u8) bool {
        return next.len > 0 and next[0] == ')';
    }

    fn parseIncreasingPrecedence(self: *Parser, left: *Node, min_prec: usize) ParserErrors!*Node {
        const next = self.next_token;
        std.debug.print("[parseIncreasingPrecedence] current token '{s}'\n", .{next});

        if (isCloseBracket(next)) {
            std.debug.print("[parseIncreasingPrecedence] close bracket ')' found, next={s}\n", .{next});
            return left;
        }

        if (!self.isBinaryOperator(next)) {
            return left;
        }

        const next_prec = self.getPrecedence(next);
        if (next_prec <= min_prec) {
            return left;
        }

        // number * ?
        self.loadNextToken();
        const next_next = self.next_token;

        if (isOpenBracket(next_next)) {
            std.debug.print("[parseIncreasingPrecedence] open bracket '(' found, next={s}\n", .{next_next});
            self.loadNextToken();
            const right = try self.parseExpression(0);
            return self.makeBinary(left, toOperator(next), right);
        }

        std.debug.print("[parseIncreasingPrecedence] not open bracket found, next={s}\n", .{next});

        //if (eql(u8, next[0], '[')) {
        //    // return parse_array_subscript
        //}

        const right = try self.parseExpression(next_prec);
        return self.makeBinary(left, toOperator(next), right);
    }

    pub fn parseExpression(self: *Parser, min_prec: usize) ParserErrors!*Node {
        // read leaf token
        // self.loadNextToken();
        var left = try self.parseLeaf();

        // read binary oprator token
        self.loadNextToken();
        while (true) {
            const node = try self.parseIncreasingPrecedence(left, min_prec);
            if (node == left) {
                break;
            }
            left = node;
            std.debug.print("[while loop] left.op={s}\n", .{left.op.text});
        }
        return left;
    }

    fn makeBinary(self: *Parser, left: *Node, op: []const u8, right: *Node) !*Node {
        std.debug.print("[make binary]: left={any} op={s} right={any}\n", .{ left.op, op, right.op });
        const node = try self.allocator.create(Node);
        node.* = Node.init(.{ .text = op });
        node.*.left = left;
        node.*.right = right;

        return @constCast(node);
    }

    fn parseLeaf(self: *Parser) !*Node {
        const node = try self.allocator.create(Node);
        const token = self.next_token;
        std.debug.print("[parseLeaf] {s}\n", .{token});
        const node_value: NodeType() = if (self.isBinaryOperator(token)) .{ .text = toOperator(token) } else .{ .int = std.fmt.parseInt(i32, token, 10) catch 0 };
        node.* = Node.init(node_value);
        return node;
    }

    fn toOperator(str: []const u8) []const u8 {
        return str;
    }
};

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

test "init parser with brackets" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "500 * ( 8 + 10 )";
    const expected = [_][]const u8{ "500", "*", "(", "8", "+", "10", ")" };
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);

    try testing.expectEqualStrings("500", p.next_token);

    // assert tokens list
    var i: usize = 0;
    var t: ?[]const u8 = p.next_token;
    while (t) |token| : (i += 1) {
        try testing.expect(i <= expected.len);
        try testing.expectEqualStrings(expected[i], token);
        t = p.tokens.next();
    }

    p.tokens.reset();
    p.loadNextToken();

    const head = p.parseExpression(0);
    std.debug.print("[head] {any}\n", .{head});
}
