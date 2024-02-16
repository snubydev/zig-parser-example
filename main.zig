const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const code = "500 * 2 + 8 * 10";

const Operators = [_][]const u8{ "*", "/", "+", "-", "==", ">=", "<=" };

const Node = struct {
    left: *Node,
    right: *Node,
    op: []u8,
};

fn isOperator(token: []const u8) bool {
    return getPrecedence(token) > 0;
}

fn getPrecedence(token: []const u8) usize {
    for (Operators, 0..) |op, i| {
        if (op.len != token.len) continue;
        if (std.mem.eql(u8, op, token)) return i + 1;
    }
    return 0;
}

fn parseIncreasingPrecedence(left: *Node, min_prec: i32) *Node {
    _ = min_prec;
    _ = left;
    //const next = getNextToken();
    return undefined;
}

const Parser = struct {
    index: usize = 0,
    tokens: [][]const u8,

    pub fn init(allocator: std.mem.Allocator, text: []const u8) !Parser {
        var it = std.mem.splitScalar(u8, text, ' ');
        var list = std.ArrayList([]const u8).init(allocator);
        while (it.next()) |token| {
            try list.append(token);
        }
        return .{ .tokens = try list.toOwnedSlice() };
    }

    pub fn getNextToken(self: Parser) ![]const u8 {
        if (self.index == self.tokens.len - 1) return error.EOF;
        return self.tokens[self.index];
    }

    pub fn reset(self: Parser) void {
        self.index = 0;
    }
};

pub fn main() !void {
    std.debug.print("Hello from zig-parser!\n", .{});
}

test "operator precedence" {
    try testing.expectEqual(@as(u32, 1), getPrecedence("*"));
    try testing.expectEqual(@as(u32, 3), getPrecedence("+"));
    try testing.expectEqual(@as(u32, 2), getPrecedence("/"));
    try testing.expectEqual(@as(u32, 4), getPrecedence("-"));
    try testing.expectEqual(@as(u32, 5), getPrecedence("=="));
}

test "is_operator" {
    for (Operators) |op| {
        try testing.expect(isOperator(op));
    }
    try testing.expect(!isOperator("%"));
    try testing.expect(!isOperator("ab"));
}

test "init parser" {
    //const allocator = std.heap.page_allocator;
    const allocator = testing.allocator;
    const parser = try Parser.init(allocator, code);
    defer testing.allocator.free(parser.tokens);
    std.debug.print("tokens {s}\n", .{parser.tokens});
}
