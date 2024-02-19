const std = @import("std");
const mem = std.mem;
const eql = std.mem.eql;
const print = std.debug.print;
const testing = std.testing;
const Node = @import("node.zig").Node;
const Parser = @import("parser.zig").Parser;

fn calculate(node: *Node) i32 {
    if (node.isLeaf()) return node.op.int;

    const left_value = calculate(node.left.?);
    const right_value = calculate(node.right.?);

    if (eql(u8, node.op.text, "+")) {
        print("[calc] {d} + {d}\n", .{ left_value, right_value });
        return left_value + right_value;
    }
    if (eql(u8, node.op.text, "*")) {
        print("[calc] {d} * {d}\n", .{ left_value, right_value });
        return left_value * right_value;
    }
    return 0;
}

pub fn main() !void {
    std.debug.print("Hello from zig-parser!\n", .{});
}

test "binary 1" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 13 * 8 + 10";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text, &operators);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}

test "binary 2" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 * 3 + 8 * 10";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text, &operators);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}

test "binary 3" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 3 * 8 * 10 + 3 + 5 + 4 * 4";
    print("[text] {s}\n", .{text});
    var parser = try Parser.init(std.heap.page_allocator, text, &operators);
    const head = try parser.parseExpression(0);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}
