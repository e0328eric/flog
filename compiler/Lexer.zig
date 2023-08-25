const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Literal = Token.Literal;
const LiteralType = Token.LiteralType;
const Token = @import("./Token.zig");
const TokenType = Token.TokenType;

allocator: Allocator,
source: []const u8,
idx: usize,

pub const Lexer = @This();
const Self = @This();

pub fn init(allocator: Allocator, source: []const u8) Self {
    return .{ .allocator = allocator, .source = source, .idx = 0 };
}

pub fn next(self: *Self) !?Token {
    const State = enum(u8) {
        start,
        whitespace,
        comment,
        integer,
        float,
        variable,
        string_literal,
        backslash,
        minus,
        loop_token,
        end,
    };

    var state = State.start;
    var token: Token = undefined;
    var start_idx: usize = undefined;
    var string_literal: ?ArrayList(u8) = null;
    errdefer {
        if (string_literal) |sl| {
            sl.deinit();
        }
    }

    blk: while (self.idx < self.source.len) : (self.idx += 1) {
        const char = self.source[self.idx];
        switch (state) {
            .start => {
                start_idx = self.idx;

                inline for ([_]struct { []const u8, State }{
                    .{ "isWhitespace", .whitespace },
                    .{ "isDigit", .integer },
                    .{ "isLower", .variable },
                }) |meta| {
                    if (@field(std.ascii, meta[0])(char)) {
                        state = meta[1];
                        continue :blk;
                    }
                }

                switch (char) {
                    // zig fmt: off
                    inline '.',
                    ',',
                    '+',
                    '*',
                    '/',
                    '|',
                    '\\',
                    '!',
                    '=',
                    '<',
                    '>',
                    '@',
                    '^',
                    '_',
                    '#',
                    '%',
                    '&',
                    '$',
                    '~',
                    ':',
                    ';',
                    '\'',
                    '(',
                    ')',
                    '{',
                    '}',
                    '[',
                    ']',
                    'A',
                    'C',
                    'D',
                    'E',
                    'F',
                    'H',
                    'I',
                    'M',
                    'P',
                    'U',
                    => |byte| {
                        token = Token.init(
                            comptime TokenType.fromByte(byte),
                            self.source[self.idx .. self.idx + 1],
                        );
                        state = .end;
                    },
                    '"' => {
                        string_literal = try ArrayList(u8).initCapacity(self.allocator, 25);
                        state = .string_literal;
                    },
                    '-' => state = .minus,
                    '`' => state = .comment,
                    'L' => state = .loop_token,
                    else => {
                        token = Token.init(.illegal, self.source[self.idx .. self.idx + 1]);
                        state = .end;
                    },
                }
            },
            .whitespace => {
                if (std.ascii.isWhitespace(char)) {
                    continue;
                }
                self.idx -= 1;
                state = .start;
            },
            .integer => {
                if (char == '.') {
                    state = .float;
                    continue;
                }
                if (!std.ascii.isDigit(char)) {
                    self.idx -= 1;
                    token = Token.init(.integer, self.source[start_idx .. self.idx + 1]);
                    state = .end;
                }
            },
            .float => if (!std.ascii.isDigit(char)) {
                self.idx -= 1;
                token = Token.init(.float, self.source[start_idx .. self.idx + 1]);
                state = .end;
            },
            .variable => if (!std.ascii.isLower(char)) {
                self.idx -= 1;
                token = Token.init(.variable, self.source[start_idx .. self.idx + 1]);
                state = .end;
            },
            .string_literal => {
                if (char == '"') {
                    if (string_literal) |*sl| {
                        token = Token.init(.string, sl);
                        string_literal = null;
                    } else {
                        token = Token.init(.string, {});
                    }
                    state = .end;
                    continue;
                }
                if (char == '\\') {
                    state = .backslash;
                    continue;
                }
                try string_literal.?.append(char);
            },
            .backslash => {
                switch (char) {
                    'n' => try string_literal.?.append('\n'),
                    't' => try string_literal.?.append('\t'),
                    '\\' => try string_literal.?.append('\\'),
                    '"' => try string_literal.?.append('"'),
                    else => {
                        if (string_literal) |sl| {
                            sl.deinit();
                            string_literal = null;
                        }
                        token = Token.init(.illegal, self.source[self.idx -| 1..self.idx]);
                        state = .end;
                        continue;
                    },
                }
                state = .string_literal;
            },
            .comment => {
                if (char == '`') {
                    state = .start;
                }
            },
            .minus => {
                if (std.ascii.isDigit(char)) {
                    state = .integer;
                    continue;
                }
                if (char == '.') {
                    state = .float;
                    continue;
                }
                self.idx -= 1;
                token = Token.init(.minus, self.source[start_idx .. self.idx + 1]);
                state = .end;
            },
            .loop_token => {
                switch (char) {
                    'K' => token = Token.init(.loopforkey, self.source[start_idx .. self.idx + 1]),
                    'V' => token = Token.init(.loopforvalue, self.source[start_idx .. self.idx + 1]),
                    else => {
                        self.idx -= 1;
                        token = Token.init(.loop, self.source[start_idx .. self.idx + 1]);
                    },
                }
                state = .end;
            },
            .end => return token,
        }
    } else {
        return switch (state) {
            .start, .comment, .whitespace => null,
            .integer => integer: {
                token = Token.init(.integer, self.source[start_idx..self.idx]);
                break :integer token;
            },
            .float => float: {
                token = Token.init(.float, self.source[start_idx..self.idx]);
                break :float token;
            },
            .variable => variable: {
                token = Token.init(.variable, self.source[start_idx..self.idx]);
                break :variable token;
            },
            .string_literal => illegal: {
                if (string_literal) |sl| {
                    sl.deinit();
                    string_literal = null;
                }
                token = Token.init(.illegal, self.source[start_idx..self.idx]);
                break :illegal token;
            },
            .backslash => illegal: {
                if (string_literal) |sl| {
                    sl.deinit();
                    string_literal = null;
                }
                token = Token.init(.illegal, self.source[self.idx -| 1..self.idx]);
                break :illegal token;
            },
            .minus => minus: {
                token = Token.init(.minus, self.source[start_idx..self.idx]);
                break :minus token;
            },
            .loop_token => loopToken: {
                token = Token.init(.loop, self.source[start_idx..self.idx]);
                break :loopToken token;
            },
            .end => token,
        };
    }
}

const expect = std.testing.expect;
const test_alloc = std.testing.allocator;
test "lexing symbols" {
    const program = "~!\nLLV@LK& &^$%";
    const expected_lst = [_]struct { TokenType, []const u8 }{
        .{ .tilde, "~" },
        .{ .bang, "!" },
        .{ .loop, "L" },
        .{ .loopforvalue, "LV" },
        .{ .at, "@" },
        .{ .loopforkey, "LK" },
        .{ .ampersand, "&" },
        .{ .ampersand, "&" },
        .{ .hat, "^" },
        .{ .dollar, "$" },
        .{ .percent, "%" },
    };
    var lexer = Lexer.init(test_alloc, program);

    for (expected_lst) |expected| {
        const token = try lexer.next();
        defer {
            if (token) |tok| {
                tok.deinit();
            }
        }
        try expect(token != null);
        try expect(token.?.toktype == expected[0]);
        try expect(@as(LiteralType, token.?.literal) == .pointer);
        try expect(std.mem.eql(u8, token.?.literal.pointer, expected[1]));
    }

    try expect(try lexer.next() == null);
}

test "lexing numbers" {
    const testing_list = [_]struct { source: []const u8, expected: TokenType }{
        .{ .source = "1234", .expected = .integer },
        .{ .source = "-401", .expected = .integer },
        .{ .source = "12.54", .expected = .float },
        .{ .source = "-123.54", .expected = .float },
        .{ .source = "-.54", .expected = .float },
    };

    inline for (testing_list) |t| {
        var lexer = Lexer.init(test_alloc, t.source);
        const token = try lexer.next();
        defer {
            if (token) |tok| {
                tok.deinit();
            }
        }

        try expect(token != null);
        try expect(token.?.toktype == t.expected);
        try expect(@as(LiteralType, token.?.literal) == .pointer);
        try expect(std.mem.eql(u8, token.?.literal.pointer, t.source));
    }
}

test "lexing strings (correct)" {
    const testing_list = [_]struct { source: []const u8, expected: []const u8 }{
        .{ .source = "\"Hello, World!\"", .expected = "Hello, World!" },
        .{ .source = "\"Hello,\\n World!\"", .expected = "Hello,\n World!" },
        .{ .source = "\"ども、サメです。\"", .expected = "ども、サメです。" },
        .{ .source = "\"ども、\\\\サメです。\"", .expected = "ども、\\サメです。" },
    };

    inline for (testing_list) |t| {
        var lexer = Lexer.init(test_alloc, t.source);
        const token = try lexer.next();
        defer {
            if (token) |tok| {
                tok.deinit();
            }
        }

        try expect(token != null);
        try expect(token.?.toktype == .string);
        try expect(@as(LiteralType, token.?.literal) == .allocated);
        try expect(std.mem.eql(u8, token.?.literal.allocated.items, t.expected));
    }
}

test "lexing strings (incorrect)" {
    const testing_list = [_]struct { source: []const u8, expected: []const u8 }{
        .{ .source = "\"Hello, World!", .expected = "\"Hello, World!" },
        .{ .source = "\"Hello, \\World!", .expected = "\\" },
        .{ .source = "\"ども、\\サメです。\"", .expected = "\\" },
    };

    inline for (testing_list) |t| {
        var lexer = Lexer.init(test_alloc, t.source);
        const token = try lexer.next();
        defer {
            if (token) |tok| {
                tok.deinit();
            }
        }

        try expect(token != null);
        try expect(token.?.toktype == .illegal);
        try expect(@as(LiteralType, token.?.literal) == .pointer);
        try expect(std.mem.eql(u8, token.?.literal.pointer, t.expected));
    }
}

test "lexing_simple_program" {
    const program =
        \\(,,P:"{} bottles of beer {}\n";): foo `the variable name is foo`;
        \\99L{#0>}{##"on the wall"foo "\nTake one down, pass it around"fooD}`looping`
    ;
    const expected_list = [_]struct { TokenType, []const u8 }{
        .{ .leftparen, "(" },
        .{ .comma, "," },
        .{ .comma, "," },
        .{ .print, "P" },
        .{ .colon, ":" },
        .{ .string, "{} bottles of beer {}\n" },
        .{ .semicolon, ";" },
        .{ .rightparen, ")" },
        .{ .colon, ":" },
        .{ .variable, "foo" },
        .{ .semicolon, ";" },
        .{ .integer, "99" },
        .{ .loop, "L" },
        .{ .leftbracket, "{" },
        .{ .sharp, "#" },
        .{ .integer, "0" },
        .{ .great, ">" },
        .{ .rightbracket, "}" },
        .{ .leftbracket, "{" },
        .{ .sharp, "#" },
        .{ .sharp, "#" },
        .{ .string, "on the wall" },
        .{ .variable, "foo" },
        .{ .string, "\nTake one down, pass it around" },
        .{ .variable, "foo" },
        .{ .decrement, "D" },
        .{ .rightbracket, "}" },
    };

    var lexer = Lexer.init(test_alloc, program);

    for (expected_list) |expected| {
        const token = try lexer.next();
        defer {
            if (token) |tok| {
                tok.deinit();
            }
        }

        try expect(token != null);
        try expect(token.?.toktype == expected[0]);
        if (expected[0] == .string) {
            try expect(@as(LiteralType, token.?.literal) == .allocated);
            try expect(std.mem.eql(u8, token.?.literal.allocated.items, expected[1]));
        } else {
            try expect(@as(LiteralType, token.?.literal) == .pointer);
            try expect(std.mem.eql(u8, token.?.literal.pointer, expected[1]));
        }
    }

    try expect(try lexer.next() == null);
}
