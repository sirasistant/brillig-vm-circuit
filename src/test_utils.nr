use crate::opcodes::{
    Opcode,
    BINARY_FIELD_OP,
    BINARY_INT_OP,
    JUMP_IF_NOT,
    JUMP_IF,
    JUMP,
    CALL,
    CONST,
    RETURN,
    FOREIGN_CALL,
    MOV,
    LOAD,
    STORE,
    BLACKBOX,
    TRAP,
    STOP,
};

fn build_jump_if(condition: Field, location: Field) -> Opcode {
    Opcode {
        code: JUMP_IF,
        operands: [condition, location, 0, 0, 0]
    }
}

fn build_load(source_pointer: Field, destination: Field) -> Opcode {
    Opcode {
        code: LOAD,
        operands: [destination, source_pointer, 0, 0, 0]
    }
}

fn build_store(source: Field, destination_pointer: Field) -> Opcode {
    Opcode {
        code: STORE,
        operands: [destination_pointer, source, 0, 0, 0]
    }
}

fn build_trap() -> Opcode {
    Opcode {
        code: TRAP,
        operands: [0; 5]
    }
}

fn build_stop() -> Opcode {
    Opcode {
        code: STOP,
        operands: [0; 5]
    }
}

fn build_return() -> Opcode {
    Opcode {
        code: RETURN,
        operands: [0; 5]
    }
}

fn build_call(destination: Field) -> Opcode {
    Opcode {
        code: CALL,
        operands: [destination, 0, 0, 0, 0]
    }
}

fn build_const(value: Field, destination: Field) -> Opcode {
    Opcode {
        code: CONST,
        operands: [destination, value, 0, 0, 0]
    }
}


fn to_tape<N, K>(opcodes: [Opcode; N], mut tape: [Field; K]) -> [Field; K] {
    let mut i = 0;
    for opcode in opcodes {
        let serialized = opcode.serialize();
        for field in serialized {
            tape[i] = field;
            i+=1;
        }
    }
    tape
}
