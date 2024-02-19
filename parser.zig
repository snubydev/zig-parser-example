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
    tokens: std.mem.SplitIterator(u8, .scalar),
    next_token: []const u8 = "",
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, text: []const u8, operators: [][]const u8) !Parser {
        const tokens: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, text, ' ');
        const next_token: []const u8 = "";
        return .{ .tokens = tokens, .binary_operators = operators, .allocator = allocator, .next_token = next_token };
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

    fn parseIncreasingPrecedence(self: *Parser, left: *Node, min_prec: usize) ParserErrors!*Node {
        const next = self.next_token;

        if (!self.isBinaryOperator(next)) {
            return left;
        }
        const next_prec = self.getPrecedence(next);
        if (next_prec <= min_prec) {
            return left;
        }
        const right = try self.parseExpression(next_prec);
        return self.makeBinary(left, toOperator(next), right);
    }

    pub fn parseExpression(self: *Parser, min_prec: usize) ParserErrors!*Node {
        // read leaf token
        self.loadNextToken();
        var left = try self.parseLeaf();

        // read binary oprator token
        self.loadNextToken();
        while (true) {
            const node = try self.parseIncreasingPrecedence(left, min_prec);
            if (node == left) {
                break;
            }
            left = node;
        }
        return left;
    }

    fn makeBinary(self: *Parser, left: *Node, op: []const u8, right: *Node) !*Node {
        // print("make binary: left={any} op={any} right={any}\n", .{ left.op, op, right.op });
        const node = try self.allocator.create(Node);
        node.* = Node.init(.{ .text = op });
        node.*.left = left;
        node.*.right = right;

        return @constCast(node);
    }

    fn parseLeaf(self: *Parser) !*Node {
        const node = try self.allocator.create(Node);
        const token = self.next_token;
        // print("[parseLeaf] {s}\n", .{token});
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
    var p = try Parser.init(testing.allocator, "", &operators);
    for (operators) |op| {
        try testing.expect(p.isBinaryOperator(op));
    }
    try testing.expect(!p.isBinaryOperator("%"));
    try testing.expect(!p.isBinaryOperator("ab"));
}

test "init parser" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 13 * 8 + 10";
    const expected = [_][]const u8{ "500", "+", "13", "*", "8", "+", "10" };
    var parser = try Parser.init(std.heap.page_allocator, text, &operators);

    // assert if parser has not red tokens in init()
    try testing.expectEqualStrings("", parser.next_token);

    // assert tokens list
    var i: usize = 0;
    while (parser.tokens.next()) |token| : (i += 1) {
        try testing.expect(i < expected.len);
        try testing.expectEqualStrings(expected[i], token);
    }
}

test "get precedence" {
    var operators = [_][]const u8{ "+", "*" };
    var p = try Parser.init(testing.allocator, "", &operators);
    try testing.expectEqual(p.getPrecedence("+"), 1);
    try testing.expectEqual(p.getPrecedence("*"), 2);
}
