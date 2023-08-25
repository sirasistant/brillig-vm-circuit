use crate::opcodes::RegisterIndex;

struct Registers<N> {
    values: [Field; N]
}

impl<N> Registers<N> {
    fn new(initial_state: [Field; N]) -> Registers<N> {
        Registers {
            values: initial_state
        }
    }

    fn get(self, index: RegisterIndex) -> Field {
        self.values[index.inner]
    }

    fn set(&mut self, index: RegisterIndex, value: Field) {
        self.values[index.inner] = value;
    }
}