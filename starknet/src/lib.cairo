/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;

    fn hash_data(ref self: TContractState, input_data: Span<u256>) -> u256;
    fn timelock(ref self: TContractState);
}

/// Simple contract for managing balance.
#[starknet::contract]
mod HelloStarknet {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{get_block_info};
    use core::keccak::keccak_u256s_be_inputs;
    use core::integer;

    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _balance: felt252) {
        self.balance.write(_balance);
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }

        fn hash_data(ref self: ContractState, input_data: Span<u256>) -> u256 {
            let hashed = keccak_u256s_be_inputs(input_data);

            // Split the hashed value into two 128-bit segments
            let low: u128 = hashed.low;
            let high: u128 = hashed.high;

            // Reverse each 128-bit segment
            let reversed_low = integer::u128_byte_reverse(low);
            let reversed_high = integer::u128_byte_reverse(high);

            // Reverse merge the reversed segments back into a u256 value
            let compatible_hash = u256 { low: reversed_high, high: reversed_low };

            compatible_hash
        }

        fn timelock(ref self: ContractState) {
            let block_info = get_block_info().unbox();
            let _current_block = block_info.block_number;
        }
    }
}
