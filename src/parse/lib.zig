const std = @import("std");
const root = @import("root");

var default_gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa: std.mem.Allocator = if (@hasDecl(root, "gpa")) root.gpa else default_gpa.allocator();

pub const Source = union(enum) {
    Atom: struct {
        atom: u8,
        text: []const u8,
    },
    Dynamic: []const u8,

    pub fn as_ref(self: Source) []const u8 {
        return switch (self) {
            .Atom => |a| a.text,
            .Dynamic => |a| a,
        };
    }

    pub fn atom(self: *const Source) ?u8 {
        return switch (self) {
            .Atom => |a| a.atom,
            .Dynamic => null,
        };
    }

    pub fn deinit(self: Source) void {
        switch (self) {
            .Dynamic => |d| gpa.free(d),
            else => {},
        }
    }

    pub fn dynamic(s: []const u8) Source {
        // Dynamic s is in lower case no need to allocate
        return .{
            .Dynamic = lower_ascii(s),
        };
    }

    pub fn dynamic_from_index(s: []const u8, semi: usize, params: []const IndexedPair) Source {
        var o = std.ArrayList(u8).init(gpa);
        o.appendSlice(s) catch unreachable;
        to_lower_slice(o.items[0..semi]);
        for (params) |p| {
            to_lower_slice(range_slice(o.items, p.a));
            if (std.mem.eql(u8, range(o.items, p.a), "charset")) {
                to_lower_slice(range_slice(o.items, p.b));
            }
        }
        return .{
            .Dynamic = o.toOwnedSlice(),
        };
    }

    fn to_lower_slice(s: []u8) void {
        for (s) |*c| {
            c.* = std.ascii.toLower(c.*);
        }
    }

    fn lower_ascii(s: []const u8) []const u8 {
        var o = gpa.alloc(u8, s.len) catch unreachable;
        for (s) |c, i| {
            o[i] = std.ascii.toLower(c);
        }
        return o;
    }
};

pub const Indexed = struct {
    a: u16 = 0,
    b: u16 = 0,
};

pub const IndexedPair = struct {
    a: Indexed,
    b: Indexed,
};

pub const ParamSource = union(enum) {
    None,
    Utf8: u16,
    One: struct {
        a: u16,
        b: IndexedPair,
    },
    Two: struct {
        a: u16,
        b: IndexedPair,
        c: IndexedPair,
    },
    Custom: struct {
        a: u16,
        b: std.ArrayList(IndexedPair),
    },

    pub fn custom(
        a: u16,
        s: []const IndexedPair,
    ) ParamSource {
        var slice = std.ArrayList(IndexedPair).init(gpa);
        slice.appendSlice(s) catch unreachable;

        return .{
            .Custom = .{
                .a = a,
                .b = slice,
            },
        };
    }

    pub fn deinit(self: *const ParamSource) void {
        switch (self.*) {
            .Custom => |*o| {
                o.b.deinit();
            },
            else => {},
        }
    }

    pub fn size_hint(self: *const ParamSource) usize {
        return switch (self.*) {
            .None => 0,
            .Utf8 => 1,
            .One => 1,
            .TWo => 2,
            .Custom => |*o| o.b.items.len,
        };
    }
};

pub const InternParams = union(enum) {
    None,
    Utf8: usize,
};

pub const Inline = union(enum) {
    Done,
    One: IndexedPair,
    Two: struct {
        a: IndexedPair,
        b: IndexedPair,
    },
};

pub const Params = union(enum) {
    None,
    Utf8,
    Inlined: struct {
        source: Source,
        inlined: Inline,
    },
    Custom: struct {
        source: Source,
        params: IndexedPairIter,
    },

    pub const IndexedPairIter = struct {
        params: []IndexedPair,
        pos: usize = 0,

        pub fn next(self: *IndexedPairIter) ?IndexedPair {
            if (self.pos < self.params.len) {
                return self.params[self.pos];
            }
            return null;
        }
    };

    pub const Item = struct {
        name: []const u8,
        value: []const u8,
    };

    const utf = Item{
        .name = "charset",
        .value = "utf-8",
    };

    pub fn find(self: *Params, key: []const u8) ?[]const u8 {
        while (self.next()) |e| {
            if (std.mem.eql(u8, key, e.name)) return e.value;
        }
        return null;
    }

    pub fn next(self: *Params) ?Item {
        switch (self.*) {
            .None => return null,
            .Utf8 => {
                self.* = .None;
                return utf;
            },
            .Inlined => |*i| {
                const ref = i.source.as_ref();
                var next_pair: ?IndexedPair = switch (i.inlined) {
                    .Done => null,
                    .One => |one| o: {
                        i.inlined = .Done;
                        break :o one;
                    },
                    .Two => |*in| o: {
                        const a = in.a;
                        i.inlined = .{ .One = in.b };
                        break :o a;
                    },
                };
                if (next_pair) |p| {
                    return Item{
                        .name = range(ref, p.a),
                        .value = range(ref, p.b),
                    };
                }
                return null;
            },
            .Custom => |*c| {
                if (c.params.next()) |p| {
                    const ref = c.source.as_ref();
                    return Item{
                        .name = range(ref, p.a),
                        .value = range(ref, p.b),
                    };
                }
                return null;
            },
        }
    }
};

pub fn range(s: []const u8, pair: Indexed) []const u8 {
    return s[@intCast(usize, pair.a)..@intCast(usize, pair.b)];
}

pub fn range_slice(s: []u8, pair: Indexed) []u8 {
    return s[@intCast(usize, pair.a)..@intCast(usize, pair.b)];
}

pub const Mime = struct {
    source: Source,
    slash: u16,
    plus: ?u16,
    params: ParamSource,

    pub inline fn type_(self: *const Mime) []const u8 {
        return self.source.as_ref()[0..@intCast(usize, self.slash)];
    }

    inline fn semicolon(self: *const Mime) ?usize {
        return switch (self.params) {
            .None => null,
            .Utf8 => |i| @intCast(usize, i),
            .One => |i| @intCast(usize, i.a),
            .Two => |i| @intCast(usize, i.a),
            .Custom => |i| @intCast(usize, i.a),
        };
    }

    pub fn deinit(self: *const Mime) void {
        self.source.deinit();
        self.params.deinit();
    }

    inline fn semicolon_or_end(self: *const Mime) usize {
        return self.semicolon() orelse self.source.as_ref().len;
    }

    pub inline fn has_params(self: *const Mime) bool {
        return self.semicolon() != null;
    }

    pub inline fn as_ref(self: *const Mime) []const u8 {
        return self.source.as_ref();
    }

    pub inline fn subtype(self: *const Mime) []const u8 {
        const end = self.semicolon_or_end();
        return self.source.as_ref()[@intCast(usize, self.slash) + 1 .. end];
    }

    pub inline fn suffix(self: *Mime) ?[]const u8 {
        if (self.plus) |idx| {
            const end = self.semicolon_or_end();
            return self.source.as_ref()[@intCast(usize, idx) + 1 .. end];
        }
        return null;
    }

    pub fn essence(self: *const Mime) []const u8 {
        return self.source.as_ref()[0..self.semicolon_or_end()];
    }

    pub inline fn params_(self: *const Mime, key: []const u8) ?[]const u8 {
        var p = self.params__();
        return p.find(key);
    }

    pub inline fn params__(self: *const Mime) Params {
        return switch (self.params) {
            .None => .None,
            .Utf8 => .Utf8,
            .One => |i| .{
                .Inlined = .{
                    .source = self.source,
                    .inlined = .{
                        .One = i.b,
                    },
                },
            },
            .Two => |i| .{
                .Inlined = .{
                    .source = self.source,
                    .inlined = .{
                        .Two = .{
                            .a = i.b,
                            .b = i.c,
                        },
                    },
                },
            },
            .Custom => |*i| .{
                .Custom = .{
                    .source = self.source,
                    .params = .{
                        .params = i.b.items,
                    },
                },
            },
        };
    }
};
