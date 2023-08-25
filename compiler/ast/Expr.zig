const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const BigInt = std.math.big.int.Managed;

expr: ExprInner,

const Self = @This();

pub const ExprType = enum(u8) {
    Null,
    Bool,
    Integer,
    Float,
    String,
    Array,
    HashMap,
};

pub const ExprInner = union(ExprType) {
    Null,
    Bool: bool,
    Integer: BigInt,
    Float: f64,
    String: ArrayList(u8),
    Array: ArrayList(Self),
    HashMap: AutoHashMap(Self, Self),
};

// Implementation of member functions

pub fn init(
    allocator: Allocator,
    comptime expr_type_enum: ExprType,
    inner: anytype,
) Allocator.Error!Self {
    const inner_typeinfo = @typeInfo(@TypeOf(inner));
    if (inner_typeinfo != .Struct) {
        @compileError(
            "Only `struct` type is allowed to be `inner` value. But " ++
                @typeName(@TypeOf(inner)) ++ "was given.",
        );
    }
    if (!inner_typeinfo.Struct.is_tuple) {
        @compileError("Nontuple value was given in `inner`.");
    }
    const inner_val = inner_typeinfo.Struct;
    const expr_type = @tagName(expr_type_enum);

    var self: Self = undefined;
    self.expr = switch (expr_type_enum) {
        .Null => @unionInit(ExprInner, expr_type, void),
        .Bool => bool_val: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Bool`");
            }
            break :bool_val @unionInit(ExprInner, expr_type, inner[0]);
        },
        .Integer => int_val: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Integer`");
            }

            var integer = try BigInt.init();
            errdefer integer.deinit();

            switch (@typeInfo(@TypeOf(inner[0]))) {
                .ComptimeInt, .Int => {
                    try integer.set(inner[0]);
                    break :int_val @unionInit(ExprInner, expr_type, integer);
                },
                .Struct => if (@TypeOf(inner[0]) == BigInt) {
                    try integer.copy(inner[0].toConst());
                    break :int_val @unionInit(ExprInner, expr_type, integer);
                },
                else => {},
            }

            @compileError("Put " ++ @typeName(BigInt) ++ " or primitive integer types.");
        },
        .Float => float_val: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Float`");
            }
            break :float_val @unionInit(ExprInner, expr_type, inner[0]);
        },
        .String => string_val: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `String`");
            }
            if (@TypeOf(inner[0]) != *ArrayList(u8)) {
                @compileError("Stmt.init moves ownerships of ArrayList(u8). So give it with a pointer.");
            }

            break :string_val @unionInit(
                ExprInner,
                expr_type,
                ArrayList(u8).fromOwnedSlice(allocator, try inner[0].toOwnedSlice()),
            );
        },
        .Array => array_val: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Array`");
            }
            if (@TypeOf(inner[0]) != *ArrayList(Self)) {
                @compileError("Stmt.init moves ownerships of ArrayList(Self). So give it with a pointer.");
            }

            break :array_val @unionInit(
                ExprInner,
                expr_type,
                ArrayList(Self).fromOwnedSlice(allocator, try inner[0].toOwnedSlice()),
            );
        },
        .HashMap => undefined,
    };

    return self;
}

pub fn deinit(self: *Self) void {
    switch (self.expr) {
        .Null, .Bool, .Float => {},
        .Integer => |*int_val| int_val.deinit(),
        .String => |str| str.deinit(),
        .Array => |array| {
            for (&array.items) |*ptr| {
                ptr.deinit();
            }
            array.deinit();
        },
        .HashMap => undefined,
    }
}
