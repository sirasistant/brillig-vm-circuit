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

fn implement_binary_field_op(op: u8, lhs: Field, rhs: Field) -> (Field, bool) {
    let mut success = true;
    let mut result_value = 0;
    if op == FIELD_ADD {
        result_value = lhs + rhs;
    } else if op == FIELD_SUB {
        result_value = lhs - rhs;
    } else if op == FIELD_MUL {
        result_value = lhs * rhs;
    } else if op == FIELD_DIV {
        result_value = lhs / rhs;
    } else if op == FIELD_EQUALS {
        result_value = if lhs == rhs { 1 } else { 0 };
    } else {
        success = false;
    }

    (result_value, success)
}

fn apply_binary_field_op<N>(lhs: RegisterIndex, rhs: RegisterIndex, result: RegisterIndex, op: u8, registers: &mut Registers<N>) -> bool {
    let lhs_value = (*registers).get(lhs);
    let rhs_value = (*registers).get(rhs);
    let (result_value, success) = implement_binary_field_op(op, lhs_value, rhs_value);
    if success {
        registers.set(result, result_value);
    }
    success
}

#[test]
fn test_apply_binary_field_op() {
    let mut registers = Registers::new([0; 3]);
    let register_0 = RegisterIndex::new(0);
    let register_1 = RegisterIndex::new(1);
    let register_2 = RegisterIndex::new(2);
    
    registers.set(register_0, 1);
    
    assert(apply_binary_field_op(register_0, register_0, register_1, FIELD_ADD, &mut registers));
    assert(registers.get(register_0) == 1);
    assert(registers.get(register_1) == 2);
    assert(registers.get(register_2) == 0);

    assert(apply_binary_field_op(register_1, register_0, register_2, FIELD_SUB, &mut registers));
    assert(registers.get(register_0) == 1);
    assert(registers.get(register_1) == 2);
    assert(registers.get(register_2) == 1);

    assert(apply_binary_field_op(register_1, register_1, register_2, FIELD_MUL, &mut registers));
    assert(registers.get(register_0) == 1);
    assert(registers.get(register_1) == 2);
    assert(registers.get(register_2) == 4);

    assert(apply_binary_field_op(register_2, register_1, register_2, FIELD_DIV, &mut registers));
    assert(registers.get(register_0) == 1);
    assert(registers.get(register_1) == 2);
    assert(registers.get(register_2) == 2);

    assert(apply_binary_field_op(register_2, register_1, register_2, FIELD_EQUALS, &mut registers));
    assert(registers.get(register_0) == 1);
    assert(registers.get(register_1) == 2);
    assert(registers.get(register_2) == 1);
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

unconstrained fn div_rem_hint(lhs: u126, rhs: u126) -> (u126, u126){
    assert(rhs != 0);
    let quo = lhs / rhs;
    let rem = rhs - (quo * rhs);
    (quo, rem)
}

// The compiler breaks if we don't get the one from a separate function
fn get_one() -> u126 {
    1 as u126
}

// TODO use BigUint for this to support precision > u125
fn implement_binary_int_op(op: u8, lhs: u125, rhs: u125, bit_size: u32) -> (u126, bool) {
    let bit_modulo = get_one() << (bit_size as u126);
    let lhs_u126 = (lhs as u126) % bit_modulo;
    let rhs_u126 = (rhs as u126) % bit_modulo;
    let mut result_value = 0 as u126;
    let mut success = true;

    if op == BIN_ADD {
        result_value = (lhs_u126 + rhs_u126) % bit_modulo;
    } else if op == BIN_SUB {
        result_value = (lhs_u126 - rhs_u126) % bit_modulo;
    } else if op == BIN_MUL {
        result_value = (lhs_u126 * rhs_u126) % bit_modulo;
    } else if op == BIN_UNSIGNED_DIV {
        let (quo, rem) = div_rem_hint(lhs_u126, rhs_u126);
        assert(quo * rhs_u126 + rem == lhs_u126);
        result_value = quo;
    } else if op == BIN_EQUALS {
        result_value = if lhs_u126 == rhs_u126 { 1 } else { 0 };
    } else if op == BIN_LESS_THAN {
        result_value = if (lhs_u126 as u125) < (rhs_u126 as u125) { 1 } else { 0 };
    } else if op == BIN_LESS_THAN_EQUALS {
        result_value = if (lhs_u126 as u125) <= (rhs_u126 as u125) { 1 } else { 0 };
    } else if op == BIN_AND {
        result_value = lhs_u126 & rhs_u126;
    } else if op == BIN_OR {
        result_value = lhs_u126 | rhs_u126;
    } else if op == BIN_XOR {
        result_value = lhs_u126 ^ rhs_u126;
    } else {
        success = false;
    }

    (result_value, success)
}

#[test]
fn test_implement_binary_int_op(){
    assert(implement_binary_int_op(BIN_ADD, 1, 2, 125).0 == 3);
    assert(implement_binary_int_op(BIN_ADD, 1, 2, 2).0 == 3);
    assert(implement_binary_int_op(BIN_ADD, 1, 2, 1).0 == 1);
    assert(implement_binary_int_op(BIN_ADD, 1, 2, 0).0 == 0);

    assert(implement_binary_int_op(BIN_SUB, 2, 1, 125).0 == 1);
    assert(implement_binary_int_op(BIN_SUB, 0, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_SUB, 1, 0, 1).0 == 1);
    assert(implement_binary_int_op(BIN_SUB, 1, 0, 0).0 == 0);

    assert(implement_binary_int_op(BIN_MUL, 2, 2, 125).0 == 4);
    assert(implement_binary_int_op(BIN_MUL, 2, 2, 2).0 == 0);
    assert(implement_binary_int_op(BIN_MUL, 3, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_MUL, 3, 1, 0).0 == 0);

    assert(implement_binary_int_op(BIN_UNSIGNED_DIV, 2, 2, 125).0 == 1);
    assert(implement_binary_int_op(BIN_UNSIGNED_DIV, 2, 2, 2).0 == 1);
    assert(implement_binary_int_op(BIN_UNSIGNED_DIV, 3, 1, 1).0 == 1);
    
    assert(implement_binary_int_op(BIN_EQUALS, 2, 2, 125).0 == 1);
    assert(implement_binary_int_op(BIN_EQUALS, 2, 2, 2).0 == 1);
    assert(implement_binary_int_op(BIN_EQUALS, 3, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_EQUALS, 1, 0, 0).0 == 1);

    assert(implement_binary_int_op(BIN_LESS_THAN, 2, 2, 125).0 == 0);
    assert(implement_binary_int_op(BIN_LESS_THAN, 2, 2, 2).0 == 0);
    assert(implement_binary_int_op(BIN_LESS_THAN, 1, 2, 2).0 == 1);
    assert(implement_binary_int_op(BIN_LESS_THAN, 3, 1, 1).0 == 0);
    assert(implement_binary_int_op(BIN_LESS_THAN, 3, 1, 1).0 == 0);

    assert(implement_binary_int_op(BIN_LESS_THAN_EQUALS, 2, 2, 125).0 == 1);
    assert(implement_binary_int_op(BIN_LESS_THAN_EQUALS, 2, 2, 2).0 == 1);
    assert(implement_binary_int_op(BIN_LESS_THAN_EQUALS, 2, 1, 2).0 == 0);
    assert(implement_binary_int_op(BIN_LESS_THAN_EQUALS, 3, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_LESS_THAN_EQUALS, 3, 1, 1).0 == 1);

    assert(implement_binary_int_op(BIN_AND, 3, 2, 125).0 == 2);
    assert(implement_binary_int_op(BIN_AND, 3, 2, 2).0 == 2);
    assert(implement_binary_int_op(BIN_AND, 3, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_AND, 3, 1, 0).0 == 0);

    assert(implement_binary_int_op(BIN_OR, 2, 1, 125).0 == 3);
    assert(implement_binary_int_op(BIN_OR, 2, 1, 2).0 == 3);
    assert(implement_binary_int_op(BIN_OR, 2, 1, 1).0 == 1);
    assert(implement_binary_int_op(BIN_OR, 2, 1, 0).0 == 0);

    assert(implement_binary_int_op(BIN_XOR, 3, 2, 125).0 == 1);
    assert(implement_binary_int_op(BIN_XOR, 3, 2, 2).0 == 1);
    assert(implement_binary_int_op(BIN_XOR, 3, 2, 1).0 == 1);
    assert(implement_binary_int_op(BIN_XOR, 3, 2, 0).0 == 0);
}

fn apply_binary_int_op<N>(lhs: RegisterIndex, rhs: RegisterIndex, result: RegisterIndex, op: u8, bit_size: u32, registers: &mut Registers<N>) -> bool {
    // TODO success = false if doesn't fit
    // Cannot cast to integer with a result in noir rn though 
    let lhs_value = (*registers).get(lhs) as u125;
    let rhs_value = (*registers).get(rhs) as u125;
    let (result_value, success) = implement_binary_int_op(op, lhs_value, rhs_value, bit_size);
    if success {
        registers.set(result, result_value as Field);
    }
    success
}

#[test]
fn test_apply_binary_int_op() {
    let mut registers = Registers::new([0; 3]);
    let lhs = RegisterIndex::new(0);
    let rhs = RegisterIndex::new(1);
    let result = RegisterIndex::new(2);
    
    registers.set(lhs, 10);
    registers.set(rhs, 20);
    assert(apply_binary_int_op(lhs, rhs, result, BIN_ADD, 1, &mut registers));
    assert(registers.get(result) == 0);
}
