use dep::brillig_vm::{
    run,
    ExecutionResult,
    TAPE_LEN,
    REGISTER_COUNT,
    MEM_COUNT,
    MAX_CALL_STACK
};

fn main(
    tape: [Field; TAPE_LEN], 
    initial_registers: [Field; REGISTER_COUNT], 
    initial_memory: [Field; MEM_COUNT], 
    initial_program_counter: Field, 
    initial_call_stack: [Field; MAX_CALL_STACK],
    initial_call_stack_pointer: u64,
) -> pub ExecutionResult {
    run(tape, initial_registers, initial_memory, initial_program_counter, initial_call_stack, initial_call_stack_pointer)
}
