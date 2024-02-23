const std = @import("std");
const eql = std.mem.eql;
const print = std.debug.print;
const Node = @import("node.zig").Node;

pub fn calculate(node: *Node) i32 {
    if (node.isLeaf()) return std.fmt.parseInt(i32, node.op, 10) catch 0;

    const left_value = calculate(node.left.?);
    const right_value = calculate(node.right.?);

    if (eql(u8, node.op, "+")) {
        print("[calc] {d} + {d}\n", .{ left_value, right_value });
        return left_value + right_value;
    }
    if (eql(u8, node.op, "*")) {
        print("[calc] {d} * {d}\n", .{ left_value, right_value });
        return left_value * right_value;
    }
    if (eql(u8, node.op, "-")) {
        print("[calc] {d} - {d}\n", .{ left_value, right_value });
        return left_value - right_value;
    }
    if (eql(u8, node.op, "/")) {
        print("[calc] {d} / {d}\n", .{ left_value, right_value });
        return @divFloor(left_value, right_value);
    }
    return 0;
}

pub fn main() !void {
    std.debug.print("Hello from zig-parser!\n", .{});
}
