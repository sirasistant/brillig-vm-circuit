use crate::opcodes::{
    RegisterIndex,
};

use crate::registers::{
    Registers,
};

global FIELD_ADD: u8 = 1;
global FIELD_SUB: u8 = 2;
global FIELD_MUL: u8 = 3;
global FIELD_DIV: u8 = 4;
global FIELD_EQUALS: u8 = 5;

fn apply_binary_field_op<N>(lhs: RegisterIndex, rhs: RegisterIndex, result: RegisterIndex, op: u8, registers: &mut Registers<N>){
    let lhs_value = (*registers).get(lhs);
    let rhs_value = (*registers).get(rhs);
    let mut result_value = 0;
    if op == FIELD_ADD {
        result_value = lhs_value + rhs_value;
    } else if op == FIELD_SUB {
        result_value = lhs_value - rhs_value;
    } else if op == FIELD_MUL {
        result_value = lhs_value * rhs_value;
    } else if op == FIELD_DIV {
        result_value = lhs_value / rhs_value;
    } else if op == FIELD_EQUALS {
        result_value = if lhs_value == rhs_value { 1 } else { 0 };
    } else {
        // Unimplemented op
        assert(false);
    }

    registers.set(result, result_value);
}


global BIN_ADD: u8 = 1;
global BIN_SUB: u8 = 2;
global BIN_MUL: u8 = 3;
global BIN_SIGNED_DIV: u8 = 4;
global BIN_UNSIGNED_DIV: u8 = 5;
global BIN_EQUALS: u8 = 6;
global BIN_LESS_THAN: u8 = 7;
global BIN_LESS_THAN_EQUALS: u8 = 8;
global BIN_AND: u8 = 9;
global BIN_OR: u8 = 10;
global BIN_XOR: u8 = 11;
global BIN_SHL: u8 = 12;
global BIN_SHR: u8 = 13;

// TODO use BigUint for this to support precision > u125
fn apply_binary_int_op<N>(lhs: RegisterIndex, rhs: RegisterIndex, result: RegisterIndex, op: u8, bit_size: u32, registers: &mut Registers<N>){
    let lhs_value = (*registers).get(lhs) as u125;
    let rhs_value = (*registers).get(rhs) as u125;
    // TODO seems like it's not liking this shift
    let bit_modulo = (1 as u126) << (bit_size as u126);
    let mut result_value: u126 = 0;

    if op == BIN_ADD {
        result_value = (lhs_value + rhs_value) as u126 % bit_modulo;
    } else {
        // Unimplemented op
        assert(false);
    }
    
    registers.set(result, result_value as Field);
}

#[test]
fn test_apply_binary_op() {
    let mut registers = Registers::new([0; 3]);
    let lhs = RegisterIndex::new(0);
    let rhs = RegisterIndex::new(1);
    let result = RegisterIndex::new(2);
    
    registers.set(lhs, 10);
    registers.set(rhs, 20);
    apply_binary_int_op(lhs, rhs, result, BIN_ADD, 1, &mut registers);
    assert(registers.get(result) == 0);
}
