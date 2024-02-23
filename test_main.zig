const std = @import("std");
const testing = std.testing;
const print = std.debug.print;
const Parser = @import("parser.zig").Parser;
const calculate = @import("main.zig").calculate;

test "calculate 1" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "500 + ( 3 + 8 ) * 2";
    print("[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
    try testing.expectEqual(522, result);
}

test "calculate 2" {
    var operators = [_][]const u8{ "+", "*" };
    var brackets = [_][]const u8{"()"};
    const text = "500 * ( 3 + 8 ) + 2";
    print("[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, &brackets);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
    try testing.expectEqual(5502, result);
}

test "calculate 3" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 13 * 8 + 10";
    print("[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
    try testing.expectEqual(614, result);
}

test "calculate 4" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 * 3 + 8 * 10";
    print("[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
    try testing.expectEqual(1580, result);
}

test "calculate 5" {
    var operators = [_][]const u8{ "+", "*" };
    const text = "500 + 3 * 8 * 10 + 3 + 5 + 4 * 4";
    print("[text] {s}\n", .{text});
    var p = try Parser.init(std.heap.page_allocator, text, &operators, null);
    const head = try p.parseExpression(0);
    defer p.deinit(head);
    const result = calculate(head);
    print("[result] {d}\n", .{result});
    try testing.expectEqual(764, result);
}
