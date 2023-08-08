const std = @import("std");

const Lexer = @import("./lexer/Lexer.zig");
const Token = @import("./lexer/Token.zig");
const TokenType = Token.TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source =
        \\~0$H: hashmap;{\'2\'+}M,\"#@!\",P",P
        \\foo bar baz 1.0I2-2--
    ;

    var lexer = Lexer.init(allocator, source);
    while (try lexer.next()) |token| {
        defer token.deinit();
        std.debug.print("{}\n", .{token});
    }
}

test "test compiler" {
    _ = @import("./lexer/Lexer.zig");
}
