const std = @import("std");

const BigInt = std.math.big.int.Managed;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const ValueType = enum(u8) {
    Null = 0,
    Bool,
    Integer,
    Float,
    String,
};

pub const Value = union(ValueType) {
    Null,
    Bool: bool,
    Integer: BigInt,
    Float: f64,
    String: ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: Allocator, value: anytype) !Self {
        return switch (@typeInfo(@TypeOf(value))) {
            .Null => .Null,
            .Bool => .{ .Bool = value },
            .Int, .ComptimeInt => .{ .Integer = try BigInt.initSet(allocator, value) },
            .Float, .ComptimeFloat => .{ .Float = value },
            .Pointer => blk: {
                var string = try ArrayList(u8).initCapacity(allocator, value.len);
                errdefer string.deinit();

                try string.appendSlice(value);
                break :blk .{ .String = string };
            },
            else => @compileError("cannot generate a Value from " ++ @typeName(@TypeOf(value)) ++ "."),
        };
    }

    pub fn deinit(self: *Self) void {
        switch (self.*) {
            inline .Integer, .String => |*inner| inner.deinit(),
            else => {},
        }
    }

    pub fn binaryOp(self: Self, comptime op: BinaryOperation, rhs: Self) switch (op) {
        .equal => bool,
        else => !Self,
    } {
        return switch (op) {
            .equal => equalValue(self, rhs),
            .add => addValue(self, rhs),
            else => undefined,
        };
    }
};

// Operations for Value
pub const BinaryOperation = enum(u8) {
    equal,
    add,
    sub,
    mul,

    fn canPerform(lhs: Value, comptime op: @This(), rhs: Value) bool {
        return switch (op) {
            .equal => @as(ValueType, lhs) == @as(ValueType, rhs),
            .add => !(lhs == .Null or lhs == .Bool) and @as(ValueType, lhs) == @as(ValueType, rhs),
            .sub,
            .mul,
            => (lhs == .Integer or lhs == .Float) and @as(ValueType, lhs) == @as(ValueType, rhs),
        };
    }
};

fn equalValue(lhs: Value, rhs: Value) bool {
    if (!BinaryOperation.canPerform(lhs, .equal, rhs)) {
        return false;
    }

    const EPSILON: f64 = 10E-13;

    return switch (lhs) {
        .Null => true,
        .Bool => lhs.Bool == rhs.Bool,
        .Integer => BigInt.eql(lhs.Integer, rhs.Integer),
        .Float => std.math.approxEqAbs(f64, lhs.Float, rhs.Float, EPSILON),
        .String => std.mem.eql(u8, lhs.String.items, rhs.String.items),
    };
}

fn addValue(lhs: Value, rhs: Value) !Value {
    if (!BinaryOperation.canPerform(lhs, .add, rhs)) {
        return .Null;
    }

    switch (lhs) {
        .Integer => {
            var output = try BigInt.init(lhs.Integer.allocator);
            errdefer output.deinit();

            try output.add(&lhs.Integer, &rhs.Integer);

            return .{ .Integer = output };
        },
        .Float => return .{ .Float = lhs.Float + rhs.Float },
        .String => {
            var output = try ArrayList(u8).initCapacity(
                lhs.String.allocator,
                lhs.String.items.len + rhs.String.items.len,
            );
            errdefer output.deinit();

            try output.appendSlice(lhs.String.items);
            try output.appendSlice(rhs.String.items);

            return .{ .String = output };
        },
        else => unreachable,
    }
}

fn subValue(lhs: Value, rhs: Value) !Value {
    if (!BinaryOperation.canPerform(lhs, .sub, rhs)) {
        return .Null;
    }

    switch (lhs) {
        .Integer => {
            var output = try BigInt.init(lhs.Integer.allocator);
            errdefer output.deinit();

            try output.sub(&lhs.Integer, &rhs.Integer);

            return .{ .Integer = output };
        },
        .Float => return .{ .Float = lhs.Float - rhs.Float },
        else => unreachable,
    }
}

test "initializing and deinitializing value" {
    const allocator = std.testing.allocator;

    var val1 = try Value.init(allocator, 12345);
    defer val1.deinit();

    var val2 = try Value.init(allocator, "Hello, World!");
    defer val2.deinit();
}

test "add values" {
    const alloc = std.testing.allocator;

    var test_list = [_]struct { Value, Value, Value }{
        .{
            try Value.init(alloc, null),
            try Value.init(alloc, null),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, true),
            try Value.init(alloc, false),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, 1234),
            try Value.init(alloc, 5678),
            try Value.init(alloc, 6912),
        },
        .{
            try Value.init(alloc, 1019799756996130681763726671436132304456781416468067415248292558306065071863627636642030949423377254718066066358518538286207211),
            try Value.init(alloc, 2359083061007888006006604634250364574319156283065532843846967242281118490306555593290031058500977555661021230026654052231000800709448290009088),
            try Value.init(alloc, 2359083061007889025806361630381046338045827719197837300628383710348533738599113899355102922128614197691970653403908770297067159227986576216299),
        },
        .{
            try Value.init(alloc, 3.72),
            try Value.init(alloc, -1.234),
            try Value.init(alloc, 2.486),
        },
        .{
            try Value.init(alloc, 1),
            try Value.init(alloc, 1.0),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, "Hello, "),
            try Value.init(alloc, "World!"),
            try Value.init(alloc, "Hello, World!"),
        },
        .{
            try Value.init(alloc, "この機械は、"),
            try Value.init(alloc, "Zig言語を使った僕の初めての実装です。"),
            try Value.init(alloc, "この機械は、Zig言語を使った僕の初めての実装です。"),
        },
        .{
            try Value.init(alloc, 1),
            try Value.init(alloc, "foo"),
            try Value.init(alloc, null),
        },
    };
    defer {
        for (&test_list) |*t| {
            t.@"0".deinit();
            t.@"1".deinit();
            t.@"2".deinit();
        }
    }

    for (test_list) |t| {
        var add_value = try addValue(t.@"0", t.@"1");
        defer add_value.deinit();
        try std.testing.expect(equalValue(add_value, t.@"2"));
    }
}

test "sub values" {
    const alloc = std.testing.allocator;

    var test_list = [_]struct { Value, Value, Value }{
        .{
            try Value.init(alloc, null),
            try Value.init(alloc, null),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, true),
            try Value.init(alloc, false),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, 1234),
            try Value.init(alloc, 5678),
            try Value.init(alloc, -4444),
        },
        .{
            try Value.init(alloc, 1019799756996130681763726671436132304456781416468067415248292558306065071863627636642030949423377254718066066358518538286207211),
            try Value.init(alloc, 2359083061007888006006604634250364574319156283065532843846967242281118490306555593290031058500977555661021230026654052231000800709448290009088),
            try Value.init(alloc, -2359083061007886986206847638119682810592484846933228387065550774213703242013997287224959194873340913630071806649399334164934442190910003801877),
        },
        .{
            try Value.init(alloc, 3.72),
            try Value.init(alloc, -1.234),
            try Value.init(alloc, 4.954),
        },
        .{
            try Value.init(alloc, 1),
            try Value.init(alloc, 1.0),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, "Hello, "),
            try Value.init(alloc, "World!"),
            try Value.init(alloc, null),
        },
        .{
            try Value.init(alloc, 1),
            try Value.init(alloc, "foo"),
            try Value.init(alloc, null),
        },
    };
    defer {
        for (&test_list) |*t| {
            t.@"0".deinit();
            t.@"1".deinit();
            t.@"2".deinit();
        }
    }

    for (test_list) |t| {
        var sub_value = try subValue(t.@"0", t.@"1");
        defer sub_value.deinit();
        try std.testing.expect(equalValue(sub_value, t.@"2"));
    }
}
