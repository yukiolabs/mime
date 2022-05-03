const lib = @import("lib.zig");
const constants = @import("constants.zig");

pub const Mime = lib.parser.Mime;
pub const MediaType = lib.MediaType;
pub const MediaRange = lib.MediaRange;

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

pub fn parse_media_type(s: []const u8) error{InvalidMime}!MediaType {
    return MediaType.parse(s);
}

pub fn parse_media_range(s: []const u8) error{InvalidMime}!MediaRange {
    return MediaRange.parse(s);
}

test {
    _ = lib;
}
