global BINARY_FIELD_OP = 1;
global BINARY_INT_OP = 2;
global JUMP_IF_NOT = 3;
global JUMP_IF = 4;
global JUMP = 5;
global CALL = 6;
global CONST = 7;
global RETURN = 8;
global FOREIGN_CALL = 9;
global MOV = 10;
global LOAD = 11;
global STORE = 12;
global BLACKBOX = 13;
global TRAP = 14;
global STOP = 15;

struct RegisterIndex {
    inner: Field,
}

impl RegisterIndex {
    fn new(inner: Field) -> RegisterIndex {
        RegisterIndex {
            inner
        }
    }
}

struct Label {
    inner: Field,
}

impl Label {
    fn new(inner: Field) -> Label {
        Label {
            inner 
        }
    }

    fn get(self) -> Field {
        self.inner
    }
}

struct BinaryFieldOp {
    op: u8,
    lhs: RegisterIndex,
    rhs: RegisterIndex,
    result: RegisterIndex,
}

struct BinaryIntOp {
    op: u8,
    lhs: RegisterIndex,
    rhs: RegisterIndex,
    result: RegisterIndex,
    bit_size: u32,
}

struct JumpIfNot {
    condition: RegisterIndex,
    location: Label,
}

struct JumpIf {
    condition: RegisterIndex,
    location: Label,
}

struct Jump {
    location: Label,
}

struct Call {
    location: Label,
}

struct Const {
    destination: RegisterIndex,
    value: Field,
}

struct Mov {
    destination: RegisterIndex,
    source: RegisterIndex,
}

struct Load {
    destination: RegisterIndex,
    source_pointer: RegisterIndex,
}

struct Store {
    destination_pointer: RegisterIndex,
    source: RegisterIndex,
}

global OPCODE_LENGTH = 6;
global OPERAND_COUNT = 5;

// No enum no party
struct Opcode {
    code: u8,
    operands: [Field; OPERAND_COUNT]
}

impl Opcode {
    fn serialize(self) -> [Field; OPCODE_LENGTH] {
        let mut serialized = [0; OPCODE_LENGTH];
        serialized[0] = self.code as Field;
        for i in 0..OPERAND_COUNT {
            serialized[i + 1] = self.operands[i];
        }
        serialized
    } 

    fn serialized_length() -> Field {
        OPCODE_LENGTH
    }

    fn is_valid(self) -> bool {
        self.code != 0
    }

    fn from_tape<N>(tape: [Field; N], offset: Field) -> Opcode {
        let code = tape[offset] as u8;
        let mut operands = [0; 5];
        for i in 0..5 {
            operands[i] = tape[offset + i + 1];
        }

        Opcode {
            code,
            operands
        }
    } 

    fn unwrap_binary_field_op(self) -> BinaryFieldOp {
        assert(self.code == BINARY_FIELD_OP);

        BinaryFieldOp {
            op: self.operands[0] as u8,
            lhs: RegisterIndex::new(self.operands[1]),
            rhs: RegisterIndex::new(self.operands[2]),
            result: RegisterIndex::new(self.operands[3]),
        }
    }

    fn unwrap_binary_int_op(self) -> BinaryIntOp {
        assert(self.code == BINARY_INT_OP);

        BinaryIntOp {
            op: self.operands[0] as u8,
            lhs: RegisterIndex::new(self.operands[1]),
            rhs: RegisterIndex::new(self.operands[2]),
            result: RegisterIndex::new(self.operands[3]),
            bit_size: self.operands[4] as u32,
        }
    }

    fn unwrap_jump_if_not(self) -> JumpIfNot {
        assert(self.code == JUMP_IF_NOT);

        JumpIfNot {
            condition: RegisterIndex::new(self.operands[0]),
            location: Label::new(self.operands[1]),
        }
    }

    fn unwrap_jump_if(self) -> JumpIf {
        assert(self.code == JUMP_IF);

        JumpIf {
            condition: RegisterIndex::new(self.operands[0]),
            location: Label::new(self.operands[1]),
        }
    }

    fn unwrap_jump(self) -> Jump {
        assert(self.code == JUMP);

        Jump {
            location: Label::new(self.operands[0]),
        }
    }

    fn unwrap_call(self) -> Call {
        assert(self.code == CALL);

        Call {
            location: Label::new(self.operands[0]),
        }
    }

    fn unwrap_const(self) -> Const {
        assert(self.code == CONST);

        Const {
            destination: RegisterIndex::new(self.operands[0]),
            value: self.operands[1],
        }
    }

    fn unwrap_mov(self) -> Mov {
        assert(self.code == MOV);

        Mov {
            destination: RegisterIndex::new(self.operands[0]),
            source: RegisterIndex::new(self.operands[1]),
        }
    }

    fn unwrap_load(self) -> Load {
        assert(self.code == LOAD);

        Load {
            destination: RegisterIndex::new(self.operands[0]),
            source_pointer: RegisterIndex::new(self.operands[1]),
        }
    }

    fn unwrap_store(self) -> Store {
        assert(self.code == STORE);

        Store {
            destination_pointer: RegisterIndex::new(self.operands[0]),
            source: RegisterIndex::new(self.operands[1]),
        }
    }
}