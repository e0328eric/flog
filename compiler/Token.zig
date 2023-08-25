const std = @import("std");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const TokenType = enum(u8) {
    // zig fmt: off
    // literals
    integer,
    float,
    string,
    variable,

    // symbols
    period,      // .
    comma,       // ,
    plus,        // +
    minus,       // -
    star,        // *
    slash,       // /
    backslash,   // \
    vert,        // |
    bang,        // !
    equal,       // =
    less,        // <
    great,       // >
    at,          // @
    hat,         // ^
    underscore,  // _
    sharp,       // #
    percent,     // %
    ampersand,   // &
    dollar,      // $
    tilde,       // ~
    colon,       // :
    semicolon,   // ;
    quote,       // '
    doublequote, // "

    // brackets
    leftparen,    // (
    rightparen,   // )
    leftbracket,  // {
    rightbracket, // }
    leftsquare,   // [
    rightsquare,  // ]

    // keywords
    assign_pop,   // the A character
    assign,       // the C character
    decrement,    // the D character
    exponent,     // the E character
    float_type,   // the F character
    hashmap,      // the H character
    integer_type, // the I character
    loop,         // the L character
    loopforkey,   // the LK character
    loopforvalue, // the LV character
    map,          // the M character
    print,        // the P character
    increment,    // the U character

    illegal = 0xFF,
// zig fmt: on

    pub fn fromByte(byte: u8) @This() {
        return switch (byte) {
            '.' => .period,
            ',' => .comma,
            '+' => .plus,
            '-' => .minus,
            '*' => .star,
            '/' => .slash,
            '\\' => .backslash,
            '|' => .vert,
            '!' => .bang,
            '=' => .equal,
            '<' => .less,
            '>' => .great,
            '@' => .at,
            '^' => .hat,
            '_' => .underscore,
            '#' => .sharp,
            '%' => .percent,
            '&' => .ampersand,
            '$' => .dollar,
            '~' => .tilde,
            ':' => .colon,
            ';' => .semicolon,
            '\'' => .quote,
            '"' => .doublequote,
            '(' => .leftparen,
            ')' => .rightparen,
            '{' => .leftbracket,
            '}' => .rightbracket,
            '[' => .leftsquare,
            ']' => .rightsquare,
            'A' => .assign_pop,
            'C' => .assign,
            'D' => .decrement,
            'E' => .exponent,
            'F' => .float_type,
            'H' => .hashmap,
            'I' => .integer_type,
            'L' => .loop,
            'M' => .map,
            'P' => .print,
            'U' => .increment,
            else => .illegal,
        };
    }
};

pub const LiteralType = enum(u2) {
    none = 0,
    pointer,
    allocated,
};

pub const Literal = union(LiteralType) {
    none,
    pointer: []const u8,
    allocated: ArrayList(u8),

    pub fn init(value: anytype) @This() {
        return switch (@TypeOf(value)) {
            []const u8 => .{ .pointer = value },
            ArrayList(u8) => @compileError("this function takes the ownership of the input."),
            *ArrayList(u8) => .{ .allocated = ArrayList(u8).fromOwnedSlice(
                value.allocator,
                value.toOwnedSlice() catch @panic("OOM"),
            ) },
            else => .none,
        };
    }

    pub fn deinit(self: @This()) void {
        switch (self) {
            .allocated => |list| list.deinit(),
            else => {},
        }
    }
};

toktype: TokenType,
literal: Literal,

pub fn init(toktype: TokenType, literal: anytype) @This() {
    return .{ .toktype = toktype, .literal = Literal.init(literal) };
}

pub fn deinit(self: @This()) void {
    self.literal.deinit();
}

pub fn stringify(self: @This(), allocator: Allocator) !ArrayList(u8) {
    var output = try ArrayList(u8).initCapacity(allocator, 50);
    errdefer output.deinit();

    const literal = switch (self.literal) {
        .none => "",
        .pointer => |ptr| ptr,
        .allocated => |data| data.items,
    };

    const writer = output.writer();
    try writer.print("<Toktype: {s}, Literal: \"{s}\">", .{ @tagName(self.toktype), literal });

    return output;
}
