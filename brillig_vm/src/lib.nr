mod opcodes;
mod registers;
mod memory;
mod test_utils;
mod binary_op;

use dep::std::{
    option::Option,
    println,
};
use opcodes::{
    RegisterIndex,
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
use binary_op::{
    apply_binary_field_op,
    apply_binary_int_op,
    FIELD_ADD,
    FIELD_SUB,
    FIELD_MUL,
    FIELD_DIV,
    FIELD_EQUALS,
};

use test_utils::{
    to_tape,
    build_jump_if,
    build_jump_if_not,
    build_jump,
    build_trap,
    build_stop,
    build_load,
    build_store,
    build_call,
    build_return,
    build_const,
    build_binary_field_op,
};


global TAPE_LEN = 180; // 30 opcodes
global MAX_ITERATIONS = 10; // low iterations for faster testing
global REGISTER_COUNT = 15;
global MEM_COUNT = 50;
global MAX_CALL_STACK: u64 = 10;

struct ExecutionResult {
    errored: bool,
    finished: bool,
    registers: [Field; REGISTER_COUNT],
    memory: [Field; MEM_COUNT],
}

// TODO: Extract implementation of opcodes to separate functions for each opcode
fn run(
    tape: [Field; TAPE_LEN], 
    initial_registers: [Field; REGISTER_COUNT], 
    initial_memory: [Field; MEM_COUNT], 
    initial_program_counter: Field, 
    initial_call_stack: [Field; MAX_CALL_STACK],
    initial_call_stack_pointer: u64,
) -> ExecutionResult {
    let mut registers = Registers::new(initial_registers);
    let mut memory = Memory::new(initial_memory);

    let mut errored = false;
    let mut finished = false;
    let mut program_counter: Field = initial_program_counter;

    let mut call_stack = initial_call_stack;
    let mut call_stack_pointer: u64 = initial_call_stack_pointer;
    
    for _ in 0..MAX_ITERATIONS {
        if !finished {
            let opcode = Opcode::from_tape(tape, program_counter * Opcode::serialized_length());
            if !opcode.is_valid() {
                errored = true;
                finished = true;
            } else {
                if opcode.code == BINARY_FIELD_OP {
                    let bin_opcode = opcode.unwrap_binary_field_op();
                    if apply_binary_field_op(bin_opcode.lhs, bin_opcode.rhs, bin_opcode.result, bin_opcode.op, &mut registers) {
                        program_counter += 1;
                    }else {
                        errored = true;
                        finished = true;
                    }
                } else if opcode.code == BINARY_INT_OP {
                    let bin_opcode = opcode.unwrap_binary_int_op();
                    if apply_binary_int_op(bin_opcode.lhs, bin_opcode.rhs, bin_opcode.result, bin_opcode.op, bin_opcode.bit_size, &mut registers){
                        program_counter += 1;
                    } else {
                        errored = true;
                        finished = true;
                    }
                } else if opcode.code == JUMP_IF {
                    let jump_if = opcode.unwrap_jump_if();
                    let condition = registers.get(jump_if.condition);
                    if condition != 0 {
                        program_counter = jump_if.location.get();
                    } else {
                        program_counter += 1;
                    }
                } else if opcode.code == JUMP_IF_NOT {
                    let jump_if_not = opcode.unwrap_jump_if_not();
                    let condition = registers.get(jump_if_not.condition);
                    if condition == 0 {
                        program_counter = jump_if_not.location.get();
                    } else {
                        program_counter += 1;
                    }
                } else if opcode.code == JUMP {
                    let jump = opcode.unwrap_jump();
                    program_counter = jump.location.get();
                } else if opcode.code == CALL {
                    if call_stack_pointer < MAX_CALL_STACK {
                        let call = opcode.unwrap_call();
                        let return_location = program_counter + 1;
                        call_stack[call_stack_pointer] = return_location;
                        call_stack_pointer += 1;
                        program_counter = call.location.get();
                    }else {
                        errored = true;
                        finished = true;
                    }
                } else if opcode.code == CONST {
                    let const_op = opcode.unwrap_const();
                    registers.set(const_op.destination, const_op.value);
                    program_counter += 1;
                } else if opcode.code == RETURN {
                    if call_stack_pointer > 0 {
                        call_stack_pointer -= 1;
                        let return_location = call_stack[call_stack_pointer];
                        program_counter = return_location;
                    }else {
                        errored = true;
                        finished = true;
                    }
                } else if opcode.code == MOV {
                    let mov = opcode.unwrap_mov();
                    registers.set(mov.destination, registers.get(mov.source));
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
                    errored = true;
                    finished = true;
                }
            }
        }
    }

    ExecutionResult {
        errored,
        finished,
        registers: registers.values,
        memory: memory.values,
    }
}

fn execution_succeeds(tape: [Field; TAPE_LEN], initial_registers: [Field; REGISTER_COUNT], initial_memory: [Field; MEM_COUNT]) -> bool {
    let result = run(tape, initial_registers, initial_memory, 0, [0; MAX_CALL_STACK], 0);
    assert(result.finished);
    !result.errored
}

#[test]
fn test_load_jmp_if() {
    let mut opcodes = [build_trap(); 4];
    
    opcodes[0] = build_load(0, 0); // Load from address stored in register 0 to register 0
    opcodes[1] = build_jump_if(0, 3); // Check for 1 in register 0
    opcodes[2] = build_trap();
    opcodes[3] = build_stop();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [1; MEM_COUNT]));

    // Else branch
    assert(!execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));
}

#[test]
fn test_jmp_if_not() {
    let mut opcodes = [build_trap(); 3];
    
    opcodes[0] = build_jump_if_not(0, 2); // Check for 0 in register 0
    opcodes[1] = build_trap();
    opcodes[2] = build_stop();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));

    // Else branch
    assert(!execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [1; REGISTER_COUNT], [0; MEM_COUNT]));
}

#[test]
fn test_jmp() {
    let mut opcodes = [build_trap(); 3];
    
    opcodes[0] = build_jump(2);
    opcodes[1] = build_trap();
    opcodes[2] = build_stop();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));
}

#[test]
fn test_load_store() {
    let mut opcodes = [build_trap(); 6];
    
    opcodes[0] = build_const(1, 0); // Write 1 to register 0
    opcodes[1] = build_store(0, 2); // Write from register 0 to address 2
    opcodes[2] = build_load(2, 1); // Load from address 2 into register 1
    opcodes[3] = build_jump_if(1, 5);
    opcodes[4] = build_trap();
    opcodes[5] = build_stop();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));
}

#[test]
fn test_call_return() {
    let mut opcodes = [build_trap(); 6];
    
    opcodes[0] = build_call(4);
    opcodes[1] = build_jump_if(0, 3); // Check for 1 in register 0 (set by called function)
    opcodes[2] = build_trap();
    opcodes[3] = build_stop();
    opcodes[4] = build_const(1, 0); // Set register 0 to 1
    opcodes[5] = build_return();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));
}

#[test]
fn test_field_add(){
    let mut opcodes = [build_trap(); 8];
    opcodes[0] = build_const(1, 0); // Write 1 to register 0
    opcodes[1] = build_const(2, 1); // Write 2 to register 1
    opcodes[2] = build_binary_field_op(0, 1, 2, FIELD_ADD); // Add register 0 and 1 and write to register 2
    opcodes[3] = build_const(3, 3); // Write 3 to register 3
    opcodes[4] = build_binary_field_op(2, 3, 4, FIELD_EQUALS); // Check if register 2 and 3 are equal and write to register 4
    opcodes[5] = build_jump_if(4, 7); // Check for 1 in register 4
    opcodes[6] = build_trap();
    opcodes[7] = build_stop();

    assert(execution_succeeds(to_tape(opcodes, [0; TAPE_LEN]), [0; REGISTER_COUNT], [0; MEM_COUNT]));
}