const std = @import("std");
const print = std.debug.print;

const Iter = struct {
    name: []const u8,
    items: std.mem.SplitIterator(u8, .scalar),

    pub fn next(self: *Iter) ?[]const u8 {
        return self.items.next();
    }
};

fn main() !void {
    print("iter ...\n", .{});
}

test "iter" {
    const tt: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, "a b cde fg", ' ');
    var parser: Iter = Iter{ .name = "some", .items = tt };

    while (parser.next()) |x| {
        print("x: {s}\n", .{x});
    }
}
