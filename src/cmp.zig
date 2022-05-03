const std = @import("std");
const lib = @import("parse/lib.zig");
const parse = @import("parse/parse.zig");

pub fn str_eql(mime: *const lib.Mime, s: []const u8) bool {
    const other = parse.parse(s, true) catch return false;
    defer other.deinit();
    return std.ascii.eqlIgnoreCase(mime.as_ref(), other.as_ref());
}

pub fn mime_eq(a: *const lib.Mime, b: *const lib.Mime) bool {
    if (eql_atom(a.source.atom(), b.source.atom()) != null) return true;
    return essence_eq(a, b) and params_eq(a, b);
}

fn essence_eq(a: *const lib.Mime, b: *const lib.Mime) bool {
    return std.mem.eql(u8, a.essence(), b.essence());
}

inline fn eql_atom(a: ?u8, b: ?u8) ?void {
    if (a != null and b != null and a.? == b.?) return;
    return null;
}

fn params_eq(a: *const lib.Mime, b: *const lib.Mime) bool {
    if (a.params.size_hint() != b.params.size_hint()) return false;
    var a_it = a.params__();
    for (a_it.next()) |e| {
        const value = b.params_(e.name);
        if (value == null or !std.mem.eql(u8, value.?, e.value)) return false;
    }
    return true;
}
