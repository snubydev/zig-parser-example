const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const FooErrors = error{
    Invalid,
    OutOfMemory,
};

const code = "500 + 13 * 8 + 10";

const BinaryOperators = [_][]const u8{ "+", "*" };

const Node = struct {
    left: ?*Node,
    right: ?*Node,
    op: i32,

    pub fn init(value: i32) Node {
        return .{ .left = null, .right = null, .op = value };
    }
};

fn isBinaryOperator(token: []const u8) bool {
    return getPrecedence(token) > 0;
}

fn getPrecedence(token: []const u8) usize {
    for (BinaryOperators, 0..) |op, i| {
        if (op.len != token.len) continue;
        if (std.mem.eql(u8, op, token)) return i + 1;
    }
    return 0;
}

const Parser = struct {
    index: usize = 0,
    tokens: std.mem.SplitIterator(u8, .scalar),
    next_token: []const u8 = "",
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, text: []const u8) !Parser {
        var tt: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, text, ' ');
        const nn = tt.next() orelse "_";
        return .{ .tokens = tt, .allocator = allocator, .next_token = nn };
        //const tt: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, text, ' ');
        //return .{ .tokens = tt, .allocator = allocator };
    }

    pub fn getNextToken(self: *Parser) []const u8 {
        return self.next_token;
    }

    pub fn loadNextToken(self: *Parser) void {
        self.next_token = self.tokens.next() orelse "_";
    }

    fn parseIncreasingPrecedence(self: *Parser, left: *Node, min_prec: usize) FooErrors!*Node {
        const next = self.getNextToken();
        //print("left:{d}, next: {s}\n", .{ left.op, next });

        if (!isBinaryOperator(next)) {
            return left;
        }
        const next_prec = getPrecedence(next);

        if (next_prec <= min_prec) {
            //print("next operator {d} is less then {d} same node\n", .{ next_prec, min_prec });
            return left;
        }

        self.loadNextToken();
        const right = try self.parseExpression(next_prec);
        return makeBinary(self, left, toOperator(next), right);
    }

    fn parseExpression(self: *Parser, min_prec: usize) FooErrors!*Node {
        var left = try self.parseLeaf();
        const old = left.op;
        while (true) {
            const node = try self.parseIncreasingPrecedence(left, min_prec);
            if (node == left) {
                break;
            }
            left = node;
        }
        const new = left.op;
        if (old != new) {
            //print("swap {d} -> {d}\n", .{ old, new });
        } else {
            //print("same node {d}\n", .{old});
        }
        return left;
    }

    pub fn makeBinary(self: *Parser, left: *Node, op: i32, right: *Node) !*Node {
        //print("make binary: left={d} op={d} right={d}\n", .{ left.op, op, right.op });
        const node = try self.allocator.create(Node);
        node.* = Node.init(op);
        node.*.left = left;
        node.*.right = right;

        return @constCast(node);
    }

    fn parseLeaf(self: *Parser) !*Node {
        const val = self.getNextToken();
        self.loadNextToken();

        //print("parseLeaf: {s}\n", .{val});
        const valInt: i32 = if (isBinaryOperator(val)) toOperator(val) else std.fmt.parseInt(i32, val, 10) catch 0;
        const node = try self.allocator.create(Node);
        node.* = Node.init(valInt);
        return node;
    }

    fn toOperator(str: []const u8) i32 {
        const idx = @as(i32, @intCast(getPrecedence(str)));
        // print("str={s}, idx={d}\n", .{ str, idx });
        return idx;
    }
};

fn isLeaf(node: *Node) bool {
    return node.left == null or node.right == null;
}

fn printBinary(head: *Node) void {
    print("[tree] {any}\n", .{head});
}

fn calculate(node: *Node) i32 {
    if (isLeaf(node)) return node.op;

    const left_value = calculate(node.left.?);
    const right_value = calculate(node.right.?);

    if (node.op == 1) {
        print("[calc] {d} + {d}\n", .{ left_value, right_value });
        return left_value + right_value;
    }
    if (node.op == 2) {
        print("[calc] {d} * {d}\n", .{ left_value, right_value });
        return left_value * right_value;
    }
    return 0;
}

pub fn main() !void {
    std.debug.print("Hello from zig-parser!\n", .{});
}

test "is_operator" {
    for (BinaryOperators) |op| {
        try testing.expect(isBinaryOperator(op));
    }
    try testing.expect(!isBinaryOperator("%"));
    try testing.expect(!isBinaryOperator("ab"));
}

test "init parser" {
    var parser = try Parser.init(std.heap.page_allocator, code);
    print("parser init done\n", .{});
    while (parser.tokens.next()) |token| {
        std.debug.print("tokens {s}\n", .{token});
    }
}

test "binary 1" {
    const text = "500 + 13 * 8 + 10";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}

test "binary 2" {
    const text = "500 * 3 + 8 * 10";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}

test "binary 3" {
    const text = "500 + 3 * 8 * 10 + 3 + 5 + 4 * 4";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}
