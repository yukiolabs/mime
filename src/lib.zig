const std = @import("std");
pub const parser = @import("./parse/parse.zig");

pub const MediaType = struct {
    mime: parser.Mime,

    pub fn parse(s: []const u8) error{InvalidMime}!MediaType {
        const mime = parser.parse(s, false) catch return error.InvalidMime;
        return MediaType{
            .mime = mime,
        };
    }

    pub fn deinit(self: *const MediaType) void {
        self.mime.deinit();
    }
};

pub const MediaRange = struct {
    mime: parser.Mime,

    pub fn parse(s: []const u8) error{InvalidMime}!MediaRange {
        const mime = parser.parse(s, true) catch return error.InvalidMime;
        return MediaRange{
            .mime = mime,
        };
    }

    pub fn deinit(self: *const MediaType) void {
        self.mime.deinit();
    }

    inline fn eql(a: []const u8, b: []const u8) bool {
        return std.mem.eql(u8, a, b);
    }

    pub fn matches(self: *const MediaRange, mt: *const MediaType) bool {
        const type_ = self.mime.type_();
        if (eql(type_, parser.STAR)) {
            std.debug.assert(eql(self.mime.subtype(), parser.STAR));
            return self.matches_params(mt);
        }
        if (!eql(type_, mt.mime.type_())) return false;
        const subtype = self.mime.subtype();
        if (eql(subtype, parser.STAR)) {
            return self.matches_params(mt);
        }
        if (!eql(subtype, mt.mime.subtype())) return false;
        // type and subtype are the same, last thing to do is check
        // that the MediaType contains all this range's parameters...
        return self.matches_params(mt);
    }

    fn matches_params(self: *const MediaRange, mt: *const MediaType) bool {
        var a = self.mime.params__();
        while (a.next()) |*e| {
            const value = mt.mime.params_(e.name);
            if (value == null and eql(e.name, "q")) continue; //skip q
            if (value == null) return false;
            if (!eql(e.value, value.?)) return false;
        }
        return true;
    }
};

test "media_range_from_str" {
    try std.testing.expectEqual(
        MediaType{ .mime = parser.TEXT_PLAIN },
        try MediaType.parse("text/plain"),
    );

    const any = try MediaRange.parse("*/*");
    try std.testing.expectEqual(parser.STAR_STAR, any.mime);

    try std.testing.expectEqualStrings(
        "image/*",
        (try MediaRange.parse("image/*")).mime.as_ref(),
    );
    try std.testing.expectEqualStrings(
        "text/*; charset=utf-8",
        (try MediaRange.parse("text/*; charset=utf-8")).mime.as_ref(),
    );
    try std.testing.expectError(error.InvalidMime, MediaRange.parse("text/*plain"));
}

test "media_range_matches" {
    try std.testing.expect(
        (MediaRange{ .mime = parser.STAR_STAR }).matches(
            &MediaType{ .mime = parser.TEXT_PLAIN },
        ),
    );
    try std.testing.expect(
        (MediaRange{ .mime = parser.TEXT_STAR }).matches(
            &MediaType{ .mime = parser.TEXT_PLAIN },
        ),
    );
    try std.testing.expect(
        (MediaRange{ .mime = parser.TEXT_STAR }).matches(
            &MediaType{ .mime = parser.TEXT_HTML },
        ),
    );
    try std.testing.expect(
        (MediaRange{ .mime = parser.TEXT_STAR }).matches(
            &MediaType{ .mime = parser.TEXT_PLAIN_UTF_8 },
        ),
    );
    try std.testing.expect(
        !(MediaRange{ .mime = parser.TEXT_STAR }).matches(
            &MediaType{ .mime = parser.IMAGE_GIF },
        ),
    );
}

test "media_range_matches_params" {
    const text_any_utf8 = try MediaRange.parse("text/*; charset=utf-8");
    try std.testing.expect(text_any_utf8.matches(
        &MediaType{ .mime = parser.TEXT_PLAIN_UTF_8 },
    ));
    try std.testing.expect(text_any_utf8.matches(
        &MediaType{ .mime = parser.TEXT_HTML_UTF_8 },
    ));
    try std.testing.expect(!text_any_utf8.matches(
        &MediaType{ .mime = parser.TEXT_HTML },
    ));
    const many_params = try MediaType.parse("text/plain; charset=utf-8; foo=bar");
    try std.testing.expect(text_any_utf8.matches(
        &many_params,
    ));
    const text_plain = try MediaRange.parse("text/plain");
    try std.testing.expect(text_plain.matches(
        &many_params,
    ));
}

test "media_range_matches_skips_q" {
    var range = try MediaRange.parse("text/*; q=0.8");
    try std.testing.expect(range.matches(&MediaType{
        .mime = parser.TEXT_PLAIN_UTF_8,
    }));
    try std.testing.expect(range.matches(&MediaType{
        .mime = parser.TEXT_HTML_UTF_8,
    }));
    range = try MediaRange.parse("text/*; charset=utf-8; q=0.8");
    try std.testing.expect(range.matches(&MediaType{
        .mime = parser.TEXT_PLAIN_UTF_8,
    }));
    try std.testing.expect(range.matches(&MediaType{
        .mime = parser.TEXT_HTML_UTF_8,
    }));
    try std.testing.expect(!range.matches(&MediaType{
        .mime = parser.TEXT_HTML,
    }));
}
