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
) -> pub ExecutionResult {
    run(tape, [0; REGISTER_COUNT], [0; MEM_COUNT], 0, [0; MAX_CALL_STACK], 0)
}
