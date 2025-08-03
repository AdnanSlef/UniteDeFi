use core::keccak::keccak_u256s_be_inputs;
use core::integer;

pub fn hash_data(input_data: Span<u256>) -> u256 {
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