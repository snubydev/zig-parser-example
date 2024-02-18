const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const Int32BinaryOperationType = fn (token: []const u8) fn (a: i32, b: i32) i32;

pub fn Operations(T: type, allocator: std.mem.Allocator) !std.StringHashMap(T) {
    return std.StringHashMap(T).init(allocator);
}

fn OperationType(T: type) type {
    return *const fn (a: T, b: T) T;
}

fn Foops(T: type) type {
    return fn (token: []const u8) fn (a: T, b: T) T;
}

fn Container(T: type, data: []const T) type {
    return struct {
        pub fn Calc(foops: Foops(T)) T {
            const op1 = foops("+");
            return op1(@as(T, data[0]), @as(T, data[1]));
        }
    };
}

fn sumInt32(a: i32, b: i32) i32 {
    return a + b;
}

fn defaultInt32(a: i32, b: i32) i32 {
    return a + b;
}

fn handlerInt32(token: []const u8) fn (a: i32, b: i32) i32 {
    if (token.len > 0) return sumInt32;
    return defaultInt32;
}

test "foops i32" {
    const foo_calc = Container(i32, &[_]i32{ 1, 2 });
    const result = foo_calc.Calc(handlerInt32);
    print("foo_calc result={d}\n", .{result});
}

fn sumFloat(a: f32, b: f32) f32 {
    return a + b;
}

fn defaultFloat(a: f32, b: f32) f32 {
    return a + b;
}

fn handlerFloat(token: []const u8) fn (a: f32, b: f32) f32 {
    if (token.len > 0) return sumFloat;
    return defaultFloat;
}

test "foops f32" {
    const foo_calc = Container(f32, &[_]f32{ 1.4, 2.63 });
    const result = foo_calc.Calc(handlerFloat);
    print("foo_calc result={d}\n", .{result});
}

// test "init" {
//     print("hello ...\n", .{});
//     var operations = try Operations(OperationType(i32), std.heap.page_allocator);
//     //defer std.heap.page_allocator.free(operations);
//
//     try operations.put("123", Sum);
//
//     const f123 = operations.get("123");
//     print("map: k={s}, v={any}\n", .{ "123", operations.get("123") });
//     const result = (f123.?)(3, 4);
//     print("result={d}\n", .{result});
//
//     print("map: k={s}, v={any}\n", .{ "7", operations.get("7") });
//
//     //const map = std.StringHashMap(void).init(testing.allocator);
//     //defer testing.allocator.free(map);
//     //print("mem type: {any}\n", .{@TypeOf(map)});
// }
