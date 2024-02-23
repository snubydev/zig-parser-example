const std = @import("std");
const eql = std.mem.eql;
const print = std.debug.print;
const Node = @import("node.zig").Node;
const Parser = @import("parser.zig").Parser;

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

fn help() void {
    std.debug.print("Usage:\n", .{});
    std.debug.print("   calc \"<expression>\"\n\n", .{});
    std.debug.print("      - expression: variables, integer numbers, operators + - * /, brackets ( )\n", .{});
    std.debug.print("      - IMPORTANT: all tokens in the expression should be separated by <space>\n\n", .{});
    std.debug.print("Example:\n", .{});
    std.debug.print("   calc \"( 5 + 3 ) * 7\"\n\n", .{});
    std.debug.print("Help:\n", .{});
    std.debug.print("   calc --help\n", .{});
}

pub fn main() !void {
    std.debug.print("Hello from zig-parser!\n", .{});

    // read args
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        help();
        return;
    }

    var operators = [_][]const u8{ "+", "-", "*", "/" };
    const text = args[1];
    print("[input] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
}
