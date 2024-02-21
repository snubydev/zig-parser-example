const NodeTypeEnum = enum { int, text };

pub const Node = struct {
    left: ?*Node = null,
    right: ?*Node = null,
    op: []const u8,

    pub fn isLeaf(self: *Node) bool {
        return self.left == null or self.right == null;
    }
};
