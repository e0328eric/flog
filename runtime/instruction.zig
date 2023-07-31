const Value = @import("./value.zig").Value;

pub const Opcode = enum(u8) {
    nop = 0,
    push,
    pop,
    call,
    ret,
    add,
    sub,
    halt = 0xfe,
    illegal = 0xff,
};

pub const Instruction = union(enum) {
    inst0: Opcode,
    inst1: struct {
        opcode: Opcode,
        value: Value,
    },
    inst2: struct {
        opcode: Opcode,
        value: struct { Value, Value },
    },
};
