const std = @import("std");

const assert = std.debug.assert;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Expr = @import("./Expr.zig");
const TokenType = @import("../Token.zig").TokenType;

allocator: Allocator,
stmt: StmtInner,

// Defined inner types
const Self = @This();

pub const StmtType = enum(u8) {
    EmptyStmt,
    Assignment,
    If,
    Loop,
    MacroDef,
    Print,
    Scope,
    Symbol,
    ExprStmt,
};

pub const StmtInner = union(enum) {
    EmptyStmt,
    Assignment: struct {
        var_name: ArrayList(u8),
        is_pop: bool,
    },
    If: struct {
        conditional: *Self,
        true_stmt: ?*Self,
        false_stmt: ?*Self,
    },
    Loop: struct {
        conditional: *Self,
        loop_stmt: ?*Self,
    },
    MacroDef: struct {
        macro_name: ArrayList(u8),
        implementation: *Self,
    },
    Print: struct {
        attribute: ?ArrayList(u8),
    },
    Scope: ArrayList(Self),
    Symbol: TokenType,
    ExprStmt: Expr,
};

// Implementation of member functions

pub fn init(
    allocator: Allocator,
    comptime stmt_type_enum: StmtType,
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
    const stmt_type = @tagName(stmt_type_enum);

    var self: Self = undefined;
    self.allocator = allocator;
    self.stmt = switch (stmt_type_enum) {
        .EmptyStmt => @unionInit(StmtInner, stmt_type, void),
        .Assignment => assignment: {
            if (inner_val.fields.len != 2) {
                @compileError("Invalid `inner` for `Assignment`");
            }
            if (@TypeOf(inner[0]) != *ArrayList(u8)) {
                @compileError("Stmt.init moves ownerships of ArrayList(u8). So give it with a pointer.");
            }
            break :assignment @unionInit(StmtInner, stmt_type, .{
                .var_name = ArrayList(u8).fromOwnedSlice(allocator, try inner[0].toOwnedSlice()),
                .is_pop = inner[1],
            });
        },
        .If => if_stmt: {
            if (inner_val.fields.len != 3) {
                @compileError("Invalid `inner` for `If`");
            }

            var conditional = try allocator.create(Self);
            errdefer {
                conditional.deinit();
                allocator.destroy(conditional);
            }
            conditional.* = inner[0];

            var true_stmt = if (inner[1]) |val| true_stmt: {
                var tmp = try allocator.create(Self);
                tmp.* = val;
                break :true_stmt tmp;
            } else null;
            errdefer {
                if (true_stmt) |ptr| {
                    ptr.deinit();
                    allocator.destroy(ptr);
                }
            }

            var false_stmt = if (inner[2]) |val| false_stmt: {
                var tmp = try allocator.create(Self);
                tmp.* = val;
                break :false_stmt tmp;
            } else null;
            errdefer {
                if (false_stmt) |ptr| {
                    ptr.deinit();
                    allocator.destroy(ptr);
                }
            }

            break :if_stmt @unionInit(StmtInner, stmt_type, .{
                .conditional = conditional,
                .true_stmt = true_stmt,
                .false_stmt = false_stmt,
            });
        },
        .Loop => loop: {
            var conditional = try allocator.create(Self);
            errdefer {
                conditional.deinit();
                allocator.destroy(conditional);
            }

            var loop_stmt: *Self = switch (inner_val.fields.len) {
                0 => null,
                1 => try allocator.create(Self),
                else => @compileError("Invalid `inner` for `Loop`"),
            };
            errdefer {
                if (loop_stmt) |ptr| {
                    ptr.deinit();
                    allocator.destroy(ptr);
                }
            }

            conditional.* = inner[0];
            if (loop_stmt) |ptr| {
                ptr.* = inner[1];
            }

            break :loop @unionInit(StmtInner, stmt_type, .{
                .conditional = conditional,
                .loop_stmt = loop_stmt,
            });
        },
        .MacroDef => macro_def: {
            if (inner_val.fields.len != 2) {
                @compileError("Invalid `inner` for `MacroDef`");
            }
            if (@TypeOf(inner[0]) != *ArrayList(u8)) {
                @compileError("Stmt.init moves ownerships of ArrayList(u8). So give it with a pointer.");
            }

            const macro_name = ArrayList(u8).fromOwnedSlice(allocator, try inner[0].toOwnedSlice());
            errdefer macro_name.deinit();

            var implementation = try allocator.create(Self);
            errdefer {
                implementation.deinit();
                allocator.destroy(implementation);
            }
            implementation.* = inner[1];

            break :macro_def @unionInit(StmtInner, stmt_type, .{
                .macro_name = macro_name,
                .implementation = implementation,
            });
        },
        .Print => print: {
            switch (inner_val.fields.len) {
                0 => break :print @unionInit(StmtInner, stmt_type, null),
                1 => {
                    if (@TypeOf(inner[0]) != *ArrayList(u8)) {
                        @compileError("Stmt.init moves ownerships of ArrayList(u8). So give it with a pointer.");
                    }
                    break :print @unionInit(
                        StmtInner,
                        stmt_type,
                        ArrayList(u8).fromOwnedSlice(allocator, try inner[0].toOwnedSlice()),
                    );
                },
                else => @compileError("Invalid `inner` for `Print`"),
            }
        },
        .Scope => scope: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Scope`");
            }
            if (@TypeOf(inner[0]) != *ArrayList(Self)) {
                @compileError("Stmt.init moves ownerships of ArrayList(Stmt). So give it with a pointer.");
            }

            break :scope @unionInit(
                StmtInner,
                stmt_type,
                ArrayList(Self).fromOwnedSlice(allocator, try inner[0].toOwnedSlice()),
            );
        },
        .Symbol => symbol: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `Symbol`");
            }

            break :symbol @unionInit(StmtInner, stmt_type, inner[0]);
        },
        .ExprStmt => expr_stmt: {
            if (inner_val.fields.len != 1) {
                @compileError("Invalid `inner` for `ExprStmt`");
            }

            break :expr_stmt @unionInit(StmtInner, stmt_type, inner[0]);
        },
    };

    return self;
}

pub fn deinit(self: *Self) void {
    switch (self.stmt) {
        .EmptyStmt, .Symbol => {},
        .Assignment => |assignment| assignment.var_name.deinit(),
        .If => |if_stmt| {
            if_stmt.conditional.deinit();
            self.allocator.destroy(if_stmt.conditional);
            if (if_stmt.true_stmt) |ptr| {
                ptr.deinit();
                self.allocator.destroy(ptr);
            }
            if (if_stmt.false_stmt) |ptr| {
                ptr.deinit();
                self.allocator.destroy(ptr);
            }
        },
        .Loop => |loop_stmt| {
            loop_stmt.conditional.deinit();
            self.allocator.destroy(loop_stmt.conditional);
            if (loop_stmt.loop_stmt) |ptr| {
                ptr.deinit();
                self.allocator.destroy(ptr);
            }
        },
        .MacroDef => |macro_def| {
            macro_def.macro_name.deinit();
            macro_def.implementation.deinit();
            self.allocator.destroy(macro_def.implementation);
        },
        .Print => |print_def| {
            if (print_def.attribute) |attr| {
                attr.deinit();
            }
        },
        .Scope => |scope_stmt| {
            for (&scope_stmt.items) |*stmt| {
                stmt.deinit();
            }
            scope_stmt.deinit();
        },
        .ExprStmt => |expr_stmt| expr_stmt.deinit(),
    }
}

// test "init and deinit statement" {}
