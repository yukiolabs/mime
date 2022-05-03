const std = @import("std");

const Names = &[_][]const u8{
    "STAR",                 "*",

    "TEXT",                 "text",
    "IMAGE",                "image",
    "AUDIO",                "audio",
    "VIDEO",                "video",
    "APPLICATION",          "application",
    "MULTIPART",            "multipart",
    "MESSAGE",              "message",
    "MODEL",                "model",
    "FONT",                 "font",

    // common text/ *
    "PLAIN",                "plain",
    "HTML",                 "html",
    "XML",                  "xml",
    "JAVASCRIPT",           "javascript",
    "CSS",                  "css",
    "CSV",                  "csv",
    "EVENT_STREAM",         "event-stream",
    "VCARD",                "vcard",
    "TAB_SEPARATED_VALUES", "tab-separated-values",

    // common application/*
    "JSON",                 "json",
    "WWW_FORM_URLENCODED",  "x-www-form-urlencoded",
    "MSGPACK",              "msgpack",
    "OCTET_STREAM",         "octet-stream",
    "PDF",                  "pdf",

    // common font/*
    "WOFF",                 "woff",
    "WOFF2",                "woff2",

    // multipart/*
    "FORM_DATA",            "form-data",

    // common image/*
    "BMP",                  "bmp",
    "GIF",                  "gif",
    "JPEG",                 "jpeg",
    "PNG",                  "png",
    "SVG",                  "svg+xml",

    // audio/*
    "BASIC",                "basic",
    "MPEG",                 "mpeg",
    "MP4",                  "mp4",
    "OGG",                  "ogg",

    // parameters
    "CHARSET",              "charset",
    "BOUNDARY",             "boundary",
};

const MIME = &[_][]const u8{
    //@ MediaType:
    "TEXT_PLAIN",                      "text/plain",                               "4",  "",  "",
    "TEXT_PLAIN_UTF_8",                "text/plain; charset=utf-8",                "4",  "",  "10",
    "TEXT_HTML",                       "text/html",                                "4",  "",  "",
    "TEXT_HTML_UTF_8",                 "text/html; charset=utf-8",                 "4",  "",  "9",
    "TEXT_CSS",                        "text/css",                                 "4",  "",  "",
    "TEXT_CSS_UTF_8",                  "text/css; charset=utf-8",                  "4",  "",  "8",
    "TEXT_JAVASCRIPT",                 "text/javascript",                          "4",  "",  "",
    "TEXT_XML",                        "text/xml",                                 "4",  "",  "",
    "TEXT_EVENT_STREAM",               "text/event-stream",                        "4",  "",  "",
    "TEXT_CSV",                        "text/csv",                                 "4",  "",  "",
    "TEXT_CSV_UTF_8",                  "text/csv; charset=utf-8",                  "4",  "",  "8",
    "TEXT_TAB_SEPARATED_VALUES",       "text/tab-separated-values",                "4",  "",  "",
    "TEXT_TAB_SEPARATED_VALUES_UTF_8", "text/tab-separated-values; charset=utf-8", "4",  "",  "25",
    "TEXT_VCARD",                      "text/vcard",                               "4",  "",  "",

    "IMAGE_JPEG",                      "image/jpeg",                               "5",  "",  "",
    "IMAGE_GIF",                       "image/gif",                                "5",  "",  "",
    "IMAGE_PNG",                       "image/png",                                "5",  "",  "",
    "IMAGE_BMP",                       "image/bmp",                                "5",  "",  "",
    "IMAGE_SVG",                       "image/svg+xml",                            "5",  "9", "",

    "FONT_WOFF",                       "font/woff",                                "4",  "",  "",
    "FONT_WOFF2",                      "font/woff2",                               "4",  "",  "",

    "APPLICATION_JSON",                "application/json",                         "11", "",  "",
    "APPLICATION_JAVASCRIPT",          "application/javascript",                   "11", "",  "",
    "APPLICATION_JAVASCRIPT_UTF_8",    "application/javascript; charset=utf-8",    "11", "",  "22",
    "APPLICATION_WWW_FORM_URLENCODED", "application/x-www-form-urlencoded",        "11", "",  "",
    "APPLICATION_OCTET_STREAM",        "application/octet-stream",                 "11", "",  "",
    "APPLICATION_MSGPACK",             "application/msgpack",                      "11", "",  "",
    "APPLICATION_PDF",                 "application/pdf",                          "11", "",  "",
    "APPLICATION_DNS",                 "application/dns-message",                  "11", "",  "",

    // media-ranges
    //@ MediaRange:
    "STAR_STAR",                       "*/*",                                      "1",  "",  "",
    "TEXT_STAR",                       "text/*",                                   "4",  "",  "",
    "IMAGE_STAR",                      "image/*",                                  "5",  "",  "",
    "VIDEO_STAR",                      "video/*",                                  "5",  "",  "",
    "AUDIO_STAR",                      "audio/*",                                  "5",  "",  "",
};

pub fn main() !void {
    var a = std.ArrayList(u8).init(std.heap.page_allocator);
    var w = a.writer();
    try w.print("// !!! DO NOT EDIT !!! Generated by build/generate.zig\n\n", .{});
    try w.print("const std=@import(\"std\");\n const lib= @import(\"lib.zig\");\n\n", .{});

    var i: usize = 0;
    while (i < Names.len) : (i += 2) {
        try w.print("pub const {s}=\"{s}\";\n", .{ Names[i], Names[i + 1] });
    }
    i = 0;
    try w.print("\npub const Atom =enum(u8){s}\n", .{"{"});
    while (i < MIME.len) : (i += 5) {
        try w.print("{s},\n", .{MIME[i]});
    }
    try w.print("\n  pub fn source(self: Atom)lib.Source{s}\n", .{"{"});
    try w.print("return switch(self){s}\n", .{"{"});
    i = 0;
    while (i < MIME.len) : (i += 5) {
        try w.print(
            ".{0s}=>lib.Source{1c}.Atom=.{1c}.atom=@enumToInt(self),.text=\"{3s}\",{2c},{2c},\n",
            .{
                MIME[i],
                '{',
                '}',
                MIME[i + 1],
            },
        );
    }
    try w.print("{s};\n\n", .{"}"});
    try w.print("{s}\n\n", .{"}"});
    i = 0;
    try w.print("{s};\n\n", .{"}"});

    i = 0;
    while (i < MIME.len) : (i += 5) {
        var plus = MIME[i + 3];
        if (plus.len == 0) {
            plus = "null";
        }
        var param = MIME[i + 4];
        if (param.len == 0) {
            try w.print("\npub const {0s}:lib.Mime=.{1c}.source=Atom.source(.{0s}),.slash={3s}, .plus={4s},.params=.None,{2c};\n", .{
                MIME[i],
                '{',
                '}',
                MIME[i + 2],
                plus,
            });
        } else {
            try w.print("\npub const {s}:lib.Mime=.{1c}.source=Atom.source(.{0s}),.slash={3s}, .plus={4s},.params=.{1c}.Utf8={5s}{2c},{2c};\n", .{
                MIME[i],
                '{',
                '}',
                MIME[i + 2],
                plus,
                param,
            });
        }
    }
    try std.fs.cwd().writeFile("src/parse/constants.zig", a.items);

    var m = std.ArrayList(u8).init(std.heap.page_allocator);
    var o = m.writer();
    try o.print("// !!! DO NOT EDIT !!! Generated by build/generate.zig\n\n", .{});
    try o.print("const std=@import(\"std\");\n const lib= @import(\"lib.zig\");\n\n", .{});
    i = 0;
    while (i < MediaTypes.len) : (i += 2) {
        try o.print("/// A MediaType representing \"{s}\"\n", .{MediaTypes[i + 1]});
        try o.print("pub const {s} =lib.MediaType{c}.mime=lib.parser.{0s}{c};\n\n", .{
            MediaTypes[i], '{', '}',
        });
    }
    i = 0;
    while (i < MediaRange.len) : (i += 2) {
        try o.print("/// A MediaRange representing \"{s}\"\n", .{MediaRange[i + 1]});
        try o.print("pub const {s} =lib.MediaRange{c}.mime=lib.parser.{0s}{c};\n\n", .{
            MediaRange[i], '{', '}',
        });
    }
    try std.fs.cwd().writeFile("src/constants.zig", m.items);
}

const MediaTypes = [_][]const u8{
    "TEXT_PLAIN",                      "text/plain",
    "TEXT_PLAIN_UTF_8",                "text/plain; charset=utf-8",
    "TEXT_HTML",                       "text/html",
    "TEXT_HTML_UTF_8",                 "text/html; charset=utf-8",
    "TEXT_CSS",                        "text/css",
    "TEXT_CSS_UTF_8",                  "text/css; charset=utf-8",
    "TEXT_JAVASCRIPT",                 "text/javascript",
    "TEXT_XML",                        "text/xml",
    "TEXT_EVENT_STREAM",               "text/event-stream",
    "TEXT_CSV",                        "text/csv",
    "TEXT_CSV_UTF_8",                  "text/csv; charset=utf-8",
    "TEXT_TAB_SEPARATED_VALUES",       "text/tab-separated-values",
    "TEXT_TAB_SEPARATED_VALUES_UTF_8", "text/tab-separated-values; charset=utf-8",
    "TEXT_VCARD",                      "text/vcard",

    "IMAGE_JPEG",                      "image/jpeg",
    "IMAGE_GIF",                       "image/gif",
    "IMAGE_PNG",                       "image/png",
    "IMAGE_BMP",                       "image/bmp",
    "IMAGE_SVG",                       "image/svg+xml",

    "FONT_WOFF",                       "font/woff",
    "FONT_WOFF2",                      "font/woff2",

    "APPLICATION_JSON",                "application/json",
    "APPLICATION_JAVASCRIPT",          "application/javascript",
    "APPLICATION_JAVASCRIPT_UTF_8",    "application/javascript; charset=utf-8",
    "APPLICATION_WWW_FORM_URLENCODED", "application/x-www-form-urlencoded",
    "APPLICATION_OCTET_STREAM",        "application/octet-stream",
    "APPLICATION_MSGPACK",             "application/msgpack",
    "APPLICATION_PDF",                 "application/pdf",
    "APPLICATION_DNS",                 "application/dns-message",
};

const MediaRange = [_][]const u8{
    "STAR_STAR",  "*/*",
    "TEXT_STAR",  "text/*",
    "IMAGE_STAR", "image/*",
    "VIDEO_STAR", "video/*",
    "AUDIO_STAR", "audio/*",
};
