use crate::opcodes::RegisterIndex;
use crate::registers::Registers;

struct Memory<N> {
    values: [Field; N],
}

impl<N> Memory<N> {
    fn new(initial_state: [Field; N]) -> Memory<N> {
        Memory {
            values: initial_state,
        }
    }

    fn load(self, source_pointer: Field) -> Field {
        self.values[source_pointer]
    }

    fn store(&mut self, value: Field, pointer: Field) {
        self.values[pointer] = value;
    }
}