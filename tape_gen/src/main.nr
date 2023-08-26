use dep::brillig_vm::{
    to_tape,
    TAPE_LEN,
    REGISTER_COUNT,
    MEM_COUNT,
    build_call,
    build_jump_if,
    build_trap,
    build_stop,
    build_const,
    build_return,
};

// Generates an example tape
fn main() -> pub [Field; TAPE_LEN] {
    let mut opcodes = [build_trap(); 6];
    
    opcodes[0] = build_call(4);
    opcodes[1] = build_jump_if(0, 3);
    opcodes[2] = build_trap();
    opcodes[3] = build_stop();
    opcodes[4] = build_const(1, 0);
    opcodes[5] = build_return();

    to_tape(opcodes, [0; TAPE_LEN])
}

