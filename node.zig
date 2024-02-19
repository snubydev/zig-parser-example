const NodeTypeEnum = enum { int, text };

pub fn NodeType() type {
    return union(NodeTypeEnum) { int: i32, text: []const u8 };
}

pub const Node = struct {
    left: ?*Node,
    right: ?*Node,
    op: NodeType(),

    pub fn init(value: NodeType()) Node {
        return .{ .left = null, .right = null, .op = value };
    }

    pub fn isLeaf(self: *Node) bool {
        return self.left == null or self.right == null;
    }
};
