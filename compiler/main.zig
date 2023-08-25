const std = @import("std");

const Lexer = @import("./Lexer.zig");
const Token = @import("./Token.zig");
const TokenType = Token.TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source =
        \\(,,P:"{} bottles of beer {}\n";): foo `the variable name is foo`;
        \\99L{#0>}{##"on the wall"foo "\nTake one down, pass it around"fooD}`looping`
    ;

    var lexer = Lexer.init(allocator, source);
    while (try lexer.next()) |token| {
        defer token.deinit();

        const token_stringify = try token.stringify(allocator);
        defer token_stringify.deinit();

        std.debug.print("{s}\n", .{token_stringify.items});
    }
}

test "test compiler" {
    _ = @import("./Lexer.zig");
}
