mod opcodes;
mod registers;
mod memory;
mod test_utils;

use dep::std::option::Option;
use opcodes::{
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
use registers::Registers;
use memory::Memory;

use test_utils::{
    to_tape,
    build_jump_if,
    build_trap,
    build_stop,
    build_load,
};


global TAPE_LEN = 180;
global MAX_ITERATIONS = 100;
global REGISTER_COUNT = 15;
global MEM_COUNT = 50;

fn main(tape: [Field; TAPE_LEN], initial_registers: [Field; REGISTER_COUNT], initial_memory: [Field; MEM_COUNT]) -> pub bool {
    let mut registers = Registers::new(initial_registers);
    let mut memory = Memory::new(initial_memory);

    let mut errored = false;
    let mut finished = false;
    let mut program_counter: Field = 0;
    
    for _ in 0..MAX_ITERATIONS {
        if !finished {
            let opcode = Opcode::from_tape(tape, program_counter * Opcode::serialized_length());
            assert(opcode.is_valid());
            if opcode.code == JUMP_IF {
                let jump_if = opcode.unwrap_jump_if();
                let condition = registers.get(jump_if.condition);
                if condition != 0 {
                    program_counter = jump_if.location.get();
                } else {
                    program_counter += 1;
                }
            } else if opcode.code == MOV {
                let mov = opcode.unwrap_mov();
                registers.set(mov.destination, registers.get(mov.source));
                program_counter += 1;
            } else if opcode.code == CONST {
                let const_op = opcode.unwrap_const();
                registers.set(const_op.destination, const_op.value);
                program_counter += 1;
            } else if opcode.code == LOAD {
                let load = opcode.unwrap_load();
                registers.set(load.destination, memory.load(registers.get(load.source_pointer)));
                program_counter += 1;
            }  else if opcode.code == STORE {
                let store = opcode.unwrap_store();
                memory.store(registers.get(store.source), registers.get(store.destination_pointer));
                program_counter += 1;
            } else if opcode.code == TRAP {
                errored = true;
                finished = true;
            } else if opcode.code == STOP {
                finished = true;
            } else {
                // Unimplemented opcode
                assert(false);
            }
        }
    }

    assert(finished);
    !errored
}


#[test]
fn test_load_jmp() {
    let mut opcodes = [build_trap(); 4];
    
    opcodes[0] = build_load(0, 0);
    opcodes[1] = build_jump_if(0, 3);
    opcodes[2] = build_trap();
    opcodes[3] = build_stop();

    assert(main(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [1; MEM_COUNT]));
}
