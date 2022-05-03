const std = @import("std");

const lib = @import("lib.zig");
const constants = @import("constants.zig");

pub const STAR = constants.STAR;
pub const TEXT = constants.TEXT;
pub const IMAGE = constants.IMAGE;
pub const AUDIO = constants.AUDIO;
pub const VIDEO = constants.VIDEO;
pub const APPLICATION = constants.APPLICATION;
pub const MULTIPART = constants.MULTIPART;
pub const MESSAGE = constants.MESSAGE;
pub const MODEL = constants.MODEL;
pub const FONT = constants.FONT;
pub const PLAIN = constants.PLAIN;
pub const HTML = constants.HTML;
pub const XML = constants.XML;
pub const JAVASCRIPT = constants.JAVASCRIPT;
pub const CSS = constants.CSS;
pub const CSV = constants.CSV;
pub const EVENT_STREAM = constants.EVENT_STREAM;
pub const VCARD = constants.VCARD;
pub const TAB_SEPARATED_VALUES = constants.TAB_SEPARATED_VALUES;
pub const JSON = constants.JSON;
pub const WWW_FORM_URLENCODED = constants.WWW_FORM_URLENCODED;
pub const MSGPACK = constants.MSGPACK;
pub const OCTET_STREAM = constants.OCTET_STREAM;
pub const PDF = constants.PDF;
pub const WOFF = constants.WOFF;
pub const WOFF2 = constants.WOFF2;
pub const FORM_DATA = constants.FORM_DATA;
pub const BMP = constants.BMP;
pub const GIF = constants.GIF;
pub const JPEG = constants.JPEG;
pub const PNG = constants.PNG;
pub const SVG = constants.SVG;
pub const BASIC = constants.BASIC;
pub const MPEG = constants.MPEG;
pub const MP4 = constants.MP4;
pub const OGG = constants.OGG;
pub const CHARSET = constants.CHARSET;
pub const BOUNDARY = constants.BOUNDARY;
pub const TEXT_PLAIN = constants.TEXT_PLAIN;
pub const TEXT_PLAIN_UTF_8 = constants.TEXT_PLAIN_UTF_8;
pub const TEXT_HTML = constants.TEXT_HTML;
pub const TEXT_HTML_UTF_8 = constants.TEXT_HTML_UTF_8;
pub const TEXT_CSS = constants.TEXT_CSS;
pub const TEXT_CSS_UTF_8 = constants.TEXT_CSS_UTF_8;
pub const TEXT_JAVASCRIPT = constants.TEXT_JAVASCRIPT;
pub const TEXT_XML = constants.TEXT_XML;
pub const TEXT_EVENT_STREAM = constants.TEXT_EVENT_STREAM;
pub const TEXT_CSV = constants.TEXT_CSV;
pub const TEXT_CSV_UTF_8 = constants.TEXT_CSV_UTF_8;
pub const TEXT_TAB_SEPARATED_VALUES = constants.TEXT_TAB_SEPARATED_VALUES;
pub const TEXT_TAB_SEPARATED_VALUES_UTF_8 = constants.TEXT_TAB_SEPARATED_VALUES_UTF_8;
pub const TEXT_VCARD = constants.TEXT_VCARD;
pub const IMAGE_JPEG = constants.IMAGE_JPEG;
pub const IMAGE_GIF = constants.IMAGE_GIF;
pub const IMAGE_PNG = constants.IMAGE_PNG;
pub const IMAGE_BMP = constants.IMAGE_BMP;
pub const IMAGE_SVG = constants.IMAGE_SVG;
pub const FONT_WOFF = constants.FONT_WOFF;
pub const FONT_WOFF2 = constants.FONT_WOFF2;
pub const APPLICATION_JSON = constants.APPLICATION_JSON;
pub const APPLICATION_JAVASCRIPT = constants.APPLICATION_JAVASCRIPT;
pub const APPLICATION_JAVASCRIPT_UTF_8 = constants.APPLICATION_JAVASCRIPT_UTF_8;
pub const APPLICATION_WWW_FORM_URLENCODED = constants.APPLICATION_WWW_FORM_URLENCODED;
pub const APPLICATION_OCTET_STREAM = constants.APPLICATION_OCTET_STREAM;
pub const APPLICATION_MSGPACK = constants.APPLICATION_MSGPACK;
pub const APPLICATION_PDF = constants.APPLICATION_PDF;
pub const APPLICATION_DNS = constants.APPLICATION_DNS;
pub const STAR_STAR = constants.STAR_STAR;
pub const TEXT_STAR = constants.TEXT_STAR;
pub const IMAGE_STAR = constants.IMAGE_STAR;
pub const VIDEO_STAR = constants.VIDEO_STAR;
pub const AUDIO_STAR = constants.AUDIO_STAR;

pub const Atom = constants.Atom;
pub const Mime = lib.Mime;
pub const Source = lib.Source;
pub const Params = lib.Params;
pub const InternParams = lib.InternParams;
pub const ParamSource = lib.ParamSource;
pub const Indexed = lib.Indexed;
pub const IndexedPair = lib.IndexedPair;
const range = lib.range;

pub const ParseError = error{
    MissingSlash,
    MissingEqual,
    MissingQuote,
    InvalidToken,
    InvalidRange,
    TooLong,
};

inline fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn parse(s: []const u8, can_range: bool) ParseError!Mime {
    if (s.len > @intCast(usize, std.math.maxInt(u16))) {
        return error.TooLong;
    }
    if (eql(s, "*/*")) {
        if (can_range) {
            return STAR_STAR;
        }
        return error.InvalidRange;
    }
    var start: usize = 0;
    var slash: u16 = 0;
    var it = iter{ .s = s };

    while (true) {
        if (it.next()) |e| {
            if (e.c == '/' and e.i > 0) {
                slash = @truncate(u16, e.i);
                start = e.i + 1;
                break;
            }
            if (is_token(e.c)) continue;
            return error.InvalidToken;
        }
        return error.MissingSlash;
    }
    var plus: ?u16 = null;

    while (true) {
        if (it.next()) |e| {
            if (e.c == '+' and e.i > start) {
                plus = @truncate(u16, e.i);
            } else if (e.c == ';' and e.i > start) {
                start = e.i;
                break;
            } else if (e.c == ' ' and e.i > start) {
                start = e.i;
                break;
            } else if (e.c == '*' and e.i == start and can_range) {
                // sublevel star can only be the first character, and the next
                // must either be the end, or `;`
                if (it.next()) |n| {
                    if (n.c == ';') {
                        start = n.i;
                        break;
                    }
                    return error.InvalidToken;
                }
                return Mime{
                    .source = intern(s, slash, .None),
                    .slash = slash,
                    .plus = plus,
                    .params = .None,
                };
            }
            if (is_token(e.c)) continue;
            return error.InvalidToken;
        }
        return Mime{
            .source = intern(s, slash, .None),
            .slash = slash,
            .plus = plus,
            .params = .None,
        };
    }
    var params = try params_from_str(s, &it, start);
    var source = switch (params) {
        .None => r: {
            // Getting here means there *was* a `;`, but then no parameters
            // after it... So let's just chop off the empty param list.
            std.debug.assert(s.len != start);
            const b = s[start];
            std.debug.assert(b == ';' or b == ' ');
            break :r intern(s[0..start], slash, .None);
        },
        .Utf8 => |o| intern(s, slash, .{ .Utf8 = @intCast(usize, o) }),
        .One => |*o| Source.dynamic_from_index(s, @intCast(usize, o.a), &[_]IndexedPair{o.b}),
        .Two => |*o| Source.dynamic_from_index(s, @intCast(usize, o.a), &[_]IndexedPair{ o.b, o.c }),
        .Custom => |*o| Source.dynamic_from_index(s, @intCast(usize, o.a), o.b.items),
    };
    return Mime{
        .source = source,
        .slash = slash,
        .plus = plus,
        .params = params,
    };
}

fn params_from_str(s: []const u8, it: *iter, start_pos: usize) ParseError!ParamSource {
    var start = start_pos;
    const param_start = @intCast(u16, start);
    start += 1;
    var params: ParamSource = .None;
    errdefer params.deinit();

    params: while (start < s.len) {
        var name: Indexed = .{};
        name: while (true) {
            if (it.next()) |c| {
                if (c.c == ' ' and c.i == start) {
                    start = c.i + 1;
                    continue :params;
                }
                if (c.c == ';' and c.i == start) {
                    start = c.i + 1;
                    continue :params;
                }
                if (c.c == '=' and c.i > start) {
                    name = .{
                        .a = @intCast(u16, start),
                        .b = @intCast(u16, c.i),
                    };
                    start = c.i + 1;
                    break :name;
                }
                if (is_token(c.c)) continue;
                return error.InvalidToken;
            }
            return error.MissingEqual;
        }
        var value: Indexed = .{};
        var is_quoted: bool = false;
        var is_quoted_pair: bool = false;
        value: while (true) {
            if (is_quoted) {
                if (is_quoted_pair) {
                    is_quoted_pair = false;
                    const c = it.next();
                    if (c == null) return error.MissingQuote;
                    if (!is_restricted_quoted_char(c.?.c)) {
                        return error.InvalidToken;
                    }
                } else {
                    const c = it.next();
                    if (c == null) return error.MissingQuote;
                    if (c.?.c == '"' and c.?.i > start) {
                        value = .{
                            .a = @intCast(u16, start),
                            .b = @intCast(u16, c.?.i + 1),
                        };
                        start = c.?.i + 1;
                        break :value;
                    } else if (c.?.c == '\\') {
                        is_quoted_pair = true;
                    } else if (is_restricted_quoted_char(c.?.c)) {} else {
                        return error.InvalidToken;
                    }
                }
            } else {
                const n = it.next();
                if (n == null) {
                    value = .{
                        .a = @intCast(u16, start),
                        .b = @intCast(u16, s.len),
                    };
                    start = s.len;
                    break :value;
                }
                const c = n.?;
                if (c.c == '"' and c.i == start) {
                    is_quoted = true;
                    start = c.i;
                } else if ((c.c == ' ' or c.c == ';') and c.i > start) {
                    value = .{
                        .a = @intCast(u16, start),
                        .b = @intCast(u16, c.i),
                    };
                    start = c.i + 1;
                    break :value;
                } else if (is_token(c.c)) {} else {
                    return error.InvalidToken;
                }
            }
        }
        switch (params) {
            .Utf8 => |b| {
                const i = b + 2;
                const cs = "charset";
                const ut = "utf-8";

                const charset = Indexed{
                    .a = i,
                    .b = @intCast(u16, cs.len) + i,
                };
                const utf8 = Indexed{
                    .a = charset.b + 1,
                    .b = charset.b + @intCast(u16, ut.len) + 1,
                };

                params = ParamSource{
                    .Two = .{
                        .a = param_start,
                        .b = .{
                            .a = charset,
                            .b = utf8,
                        },
                        .c = .{
                            .a = name,
                            .b = value,
                        },
                    },
                };
            },
            .One => |o| {
                params = ParamSource{
                    .Two = .{
                        .a = o.a,
                        .b = o.b,
                        .c = .{ .a = name, .b = value },
                    },
                };
            },
            .Two => |o| {
                params = ParamSource.custom(o.a, &[_]IndexedPair{
                    o.b, o.c, .{ .a = name, .b = value },
                });
            },
            .Custom => |*o| {
                o.b.append(.{ .a = name, .b = value }) catch unreachable;
            },
            .None => {
                const eql0 = std.ascii.eqlIgnoreCase(
                    "charset",
                    range(s, name),
                );
                const eql1 = std.ascii.eqlIgnoreCase(
                    "utf-8",
                    range(s, value),
                );
                if (param_start + 2 == name.a and eql0 and eql1) {
                    params = ParamSource{ .Utf8 = param_start };
                    continue :params;
                }
                params = ParamSource{
                    .One = .{
                        .a = param_start,
                        .b = .{
                            .a = name,
                            .b = value,
                        },
                    },
                };
            },
        }
    }
    return params;
}

const iter = struct {
    s: []const u8,
    p: usize = 0,
    const e = struct {
        c: u8,
        i: usize,
    };
    fn next(self: *iter) ?e {
        if (self.p < self.s.len) {
            defer {
                self.p += 1;
            }
            return e{ .c = self.s[self.p], .i = self.p };
        }
        return null;
    }
};

const TOKEN_MAP: [256]u8 = [_]u8{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

fn is_token(c: u8) bool {
    return TOKEN_MAP[@intCast(usize, c)] != 0;
}

fn is_restricted_quoted_char(c: u8) bool {
    return c == 9 or (c > 31 and c != 127);
}

fn intern_charset_utf8(s: []const u8, slash: usize, semicolon: usize) Source {
    const top = s[0..slash];
    const sub = s[slash + 1 .. semicolon];
    if (eql(top, TEXT)) {
        if (eql(sub, PLAIN)) {
            return Atom.source(.TEXT_PLAIN_UTF_8);
        }
        if (eql(sub, HTML)) {
            return Atom.source(.TEXT_HTML_UTF_8);
        }
        if (eql(sub, CSS)) {
            return Atom.source(.TEXT_CSS_UTF_8);
        }
        if (eql(sub, CSV)) {
            return Atom.source(.TEXT_CSV_UTF_8);
        }
        if (eql(sub, TAB_SEPARATED_VALUES)) {
            return Atom.source(.TEXT_TAB_SEPARATED_VALUES_UTF_8);
        }
    }
    if (eql(top, APPLICATION)) {
        if (eql(sub, JAVASCRIPT)) {
            return Atom.source(.TEXT_PLAIN_UTF_8);
        }
    }
    return Source.dynamic(s);
}

fn intern_no_params(s: []const u8, slash: usize) Source {
    const top = s[0..slash];
    const sub = s[slash + 1 ..];
    switch (slash) {
        4 => {
            if (eql(top, TEXT)) {
                switch (sub.len) {
                    1 => {
                        if (sub[0] == '*') {
                            return Atom.source(.TEXT_STAR);
                        }
                    },
                    3 => {
                        if (eql(sub, CSS)) {
                            return Atom.source(.TEXT_CSS);
                        }
                        if (eql(sub, XML)) {
                            return Atom.source(.TEXT_XML);
                        }
                        if (eql(sub, CSV)) {
                            return Atom.source(.TEXT_CSV);
                        }
                    },
                    4 => {
                        if (eql(sub, HTML)) {
                            return Atom.source(.TEXT_HTML);
                        }
                    },
                    5 => {
                        if (eql(sub, PLAIN)) {
                            return Atom.source(.TEXT_PLAIN);
                        }
                        if (eql(sub, VCARD)) {
                            return Atom.source(.TEXT_VCARD);
                        }
                    },
                    10 => {
                        if (eql(sub, JAVASCRIPT)) {
                            return Atom.source(.TEXT_JAVASCRIPT);
                        }
                    },
                    12 => {
                        if (eql(sub, EVENT_STREAM)) {
                            return Atom.source(.TEXT_EVENT_STREAM);
                        }
                    },
                    20 => {
                        if (eql(sub, TAB_SEPARATED_VALUES)) {
                            return Atom.source(.TEXT_TAB_SEPARATED_VALUES);
                        }
                    },
                    else => {},
                }
            } else if (eql(top, FONT)) {
                switch (sub.len) {
                    4 => {
                        if (eql(sub, WOFF)) {
                            return Atom.source(.FONT_WOFF);
                        }
                    },
                    5 => {
                        if (eql(sub, WOFF2)) {
                            return Atom.source(.FONT_WOFF2);
                        }
                    },
                    else => {},
                }
            }
        },
        5 => {
            if (eql(top, IMAGE)) {
                switch (sub.len) {
                    1 => {
                        if (sub[0] == '*') {
                            return Atom.source(.IMAGE_STAR);
                        }
                    },
                    3 => {
                        if (eql(sub, PNG)) {
                            return Atom.source(.IMAGE_PNG);
                        }
                        if (eql(sub, GIF)) {
                            return Atom.source(.IMAGE_GIF);
                        }
                        if (eql(sub, BMP)) {
                            return Atom.source(.IMAGE_BMP);
                        }
                    },
                    4 => {
                        if (eql(sub, JPEG)) {
                            return Atom.source(.IMAGE_JPEG);
                        }
                    },
                    7 => {
                        if (eql(sub, SVG)) {
                            return Atom.source(.IMAGE_SVG);
                        }
                    },
                    else => {},
                }
            } else if (eql(top, VIDEO)) {
                if (sub.len == 1 and sub[0] == '*') {
                    return Atom.source(.VIDEO_STAR);
                }
            } else if (eql(top, AUDIO)) {
                if (sub.len == 1 and sub[0] == '*') {
                    return Atom.source(.AUDIO_STAR);
                }
            }
        },
        11 => {
            if (eql(top, APPLICATION)) {
                switch (sub.len) {
                    3 => {
                        if (eql(sub, PDF)) {
                            return Atom.source(.APPLICATION_PDF);
                        }
                    },
                    4 => {
                        if (eql(sub, JSON)) {
                            return Atom.source(.APPLICATION_JSON);
                        }
                    },
                    7 => {
                        if (eql(sub, MSGPACK)) {
                            return Atom.source(.APPLICATION_MSGPACK);
                        }
                    },
                    10 => {
                        if (eql(sub, JAVASCRIPT)) {
                            return Atom.source(.APPLICATION_JAVASCRIPT);
                        }
                    },
                    11 => {
                        if (eql(sub, "dns-message")) {
                            return Atom.source(.APPLICATION_DNS);
                        }
                    },
                    13 => {
                        if (eql(sub, OCTET_STREAM)) {
                            return Atom.source(.APPLICATION_OCTET_STREAM);
                        }
                    },
                    21 => {
                        if (eql(sub, WWW_FORM_URLENCODED)) {
                            return Atom.source(.APPLICATION_WWW_FORM_URLENCODED);
                        }
                    },
                    else => {},
                }
            }
        },
        else => {},
    }
    return Source.dynamic(s);
}

fn intern(s: []const u8, slash: u16, params: InternParams) Source {
    std.debug.assert(s.len > @intCast(usize, slash));
    return switch (params) {
        .Utf8 => |semicolon| intern_charset_utf8(s, @intCast(usize, slash), semicolon),
        .None => intern_no_params(s, @intCast(usize, slash)),
    };
}

test "test_lookup_tables" {
    for (TOKEN_MAP) |c, i| {
        const should: bool = switch (@truncate(u8, i)) {
            'a'...'z',
            'A'...'Z',
            '0'...'9',
            '!',
            '#',
            '$',
            '%',
            '&',
            '\'',
            '+',
            '-',
            '.',
            '^',
            '_',
            '`',
            '|',
            '~',
            => true,
            else => false,
        };
        try std.testing.expect(@as(bool, c != 0) == should);
    }
}

test "text_plain" {
    const mime = try parse("text/plain", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expect(!mime.has_params());
    try std.testing.expectEqualStrings("text/plain", mime.as_ref());
}

test "text_plain_uppercase" {
    const mime = try parse("TEXT/PLAIN", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expect(!mime.has_params());
    try std.testing.expectEqualStrings("text/plain", mime.as_ref());
}

test "text_plain_charset_utf8" {
    const mime = try parse("text/plain; charset=utf-8", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
    try std.testing.expectEqualStrings("text/plain; charset=utf-8", mime.as_ref());
}

test "text_plain_charset_utf8_uppercase" {
    const mime = try parse("TEXT/PLAIN; CHARSET=UTF-8", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
    try std.testing.expectEqualStrings("text/plain; charset=utf-8", mime.as_ref());
}

test "text_plain_charset_utf8_quoted" {
    const mime = try parse("text/plain; charset=\"utf-8\"", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("\"utf-8\"", mime.params_("charset").?);
    try std.testing.expectEqualStrings("text/plain; charset=\"utf-8\"", mime.as_ref());
}

test "text_plain_charset_utf8_extra" {
    const mime = try parse("text/plain; charset=utf-8; foo=bar", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
    try std.testing.expectEqualStrings("bar", mime.params_("foo").?);
    try std.testing.expectEqualStrings("text/plain; charset=utf-8; foo=bar", mime.as_ref());
}

test "text_plain_charset_utf8_extra_uppercase" {
    const mime = try parse("TEXT/PLAIN; CHARSET=UTF-8; FOO=BAR", true);
    defer mime.deinit();

    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
    try std.testing.expectEqualStrings("BAR", mime.params_("foo").?);
    try std.testing.expectEqualStrings("text/plain; charset=utf-8; foo=BAR", mime.as_ref());
}

test "charset_utf8_extra_spaces" {
    const mime = try parse("text/plain  ;  charset=utf-8  ;  foo=bar", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
    try std.testing.expectEqualStrings("bar", mime.params_("foo").?);
    try std.testing.expectEqualStrings("text/plain  ;  charset=utf-8  ;  foo=bar", mime.as_ref());
}

test "subtype_space_before_params" {
    const mime = try parse("text/plain ; charset=utf-8", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
}

test "params_space_before_semi" {
    const mime = try parse("text/plain; charset=utf-8 ; foo=ba", true);
    try std.testing.expectEqualStrings("text", mime.type_());
    try std.testing.expectEqualStrings("plain", mime.subtype());
    try std.testing.expectEqualStrings("utf-8", mime.params_("charset").?);
}

test "param_value_empty_quotes" {
    const mime = try parse("audio/wave; codecs=\"\"", true);
    try std.testing.expectEqualStrings("audio/wave; codecs=\"\"", mime.as_ref());
}

test "semi_colon_but_empty_params" {
    const cases = [_][]const u8{
        "text/event-stream;",
        "text/event-stream; ",
        "text/event-stream;       ",
        "text/event-stream ; ",
    };
    for (cases) |case| {
        const mime = try parse(case, true);
        try std.testing.expectEqualStrings("text", mime.type_());
        try std.testing.expectEqualStrings("event-stream", mime.subtype());
        try std.testing.expect(!mime.has_params());
        try std.testing.expectEqualStrings("text/event-stream", mime.as_ref());
    }
}

test "error_type_spaces" {
    try std.testing.expectError(error.InvalidToken, parse("te xt/plain", true));
}

test "error_type_lf" {
    try std.testing.expectError(error.InvalidToken, parse("te\nxt/plain", true));
}

test "error_type_cr" {
    try std.testing.expectError(error.InvalidToken, parse("te\rxt/plain", true));
}

test "error_subtype_spaces" {
    try std.testing.expectError(error.MissingEqual, parse("text/plai n", true));
}

test "error_subtype_crlf" {
    try std.testing.expectError(error.InvalidToken, parse("text/\r\nplain", true));
}

test "error_param_name_crlf" {
    try std.testing.expectError(error.InvalidToken, parse("text/plain;\r\ncharset=utf-8", true));
}

test "error_param_value_quoted_crlf" {
    try std.testing.expectError(error.InvalidToken, parse("text/plain;charset=\"\r\nutf-8\"", true));
}

test "error_param_space_before_equals" {
    try std.testing.expectError(error.InvalidToken, parse("text/plain; charset =utf-8", true));
}

test "error_param_space_after_equals" {
    try std.testing.expectError(error.InvalidToken, parse("text/plain; charset= utf-8", true));
}
