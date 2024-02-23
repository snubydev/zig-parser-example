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

    pub fn getNextToken(self: *Parser) []const u8 {
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
