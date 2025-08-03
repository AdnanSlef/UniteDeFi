mod escrow_dst {
    use crate::timelock::{
        Timelocks,
        dst_withdrawal_start, dst_pub_withdrawal_start, dst_cancellation_start,
    };
    use crate::util::hash_data;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::integer::u256;

    // Minimal ERC20 interface
    #[starknet::interface]
    trait IERC20<TContractState> {
        fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub struct Immutables {
        pub timelocks: Timelocks,
        pub maker: ContractAddress,          // receives tokens on dst chain
        pub taker: ContractAddress,          // allowed to private-withdraw / cancel
        pub token: ContractAddress,          // escrowed asset (ERC-20)
        pub amount: u256,
        pub safety_deposit: u256,            // paid to caller on success/cancel
        pub hashlock: u256,                  // keccak(secret) as u256
    }

    #[starknet::contract]
    mod EscrowDst {
        use super::{
            Immutables, Timelocks, IERC20Dispatcher, IERC20DispatcherTrait,
            ContractAddress, get_caller_address, get_block_timestamp,
            dst_withdrawal_start, dst_pub_withdrawal_start, dst_cancellation_start, hash_data,
        };
        use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
        use core::integer::u256;

        #[storage]
        struct Storage {
            immutables: Immutables,
            rescue_delay: u64,
            eth_token: ContractAddress,      // ERC-20 used to pay the safety deposit
        }

        // constructor(uint32 rescueDelay)
        #[constructor]
        fn constructor(ref self: ContractState, rescue_delay: u64, eth_token: ContractAddress, imm: Immutables) {
            let now = get_block_timestamp();
            let tl = Timelocks { deployed_at: now, src: imm.timelocks.src, dst: imm.timelocks.dst };
            let imm2 = Immutables {
                timelocks: tl,
                maker: imm.maker,
                taker: imm.taker,
                token: imm.token,
                amount: imm.amount,
                safety_deposit: imm.safety_deposit,
                hashlock: imm.hashlock,
            };
            self.immutables.write(imm2);
            self.rescue_delay.write(rescue_delay);
            self.eth_token.write(eth_token);
        }

        /// withdraw(secret): only taker, window [DstWithdrawal, DstCancellation)
        #[external(v0)]
        fn withdraw(ref self: ContractState, secret: Span<u256>, imm: Immutables) {
            assert_valid_immutables(@self, imm);
            // onlyTaker
            if get_caller_address() != imm.taker { panic!() }

            let now: u64 = get_block_timestamp();
            let t = imm.timelocks;
            let w_start: u64 = dst_withdrawal_start(@t);
            let c_start: u64 = dst_cancellation_start(@t);
            if now < w_start || now >= c_start { panic!() }  // window check

            _withdraw(ref self, secret, imm);
        }

        /// publicWithdraw(secret): anyone, window [DstPublicWithdrawal, DstCancellation)
        #[external(v0)]
        fn public_withdraw(ref self: ContractState, secret: Span<u256>, imm: Immutables) {
            assert_valid_immutables(@self, imm);

            let now: u64 = get_block_timestamp();
            let t = imm.timelocks;
            let pw_start: u64 = dst_pub_withdrawal_start(@t);
            let c_start: u64 = dst_cancellation_start(@t);
            if now < pw_start || now >= c_start { panic!() }

            _withdraw(ref self, secret, imm);
        }

        /// cancel(): only taker, only after DstCancellation
        #[external(v0)]
        fn cancel(ref self: ContractState, imm: Immutables) {
            assert_valid_immutables(@self, imm);
            if get_caller_address() != imm.taker { panic!() }

            let now: u64 = get_block_timestamp();
            let t = imm.timelocks;
            let c_start: u64 = dst_cancellation_start(@t);
            if now < c_start { panic!() }

            // Return escrowed tokens to taker
            IERC20Dispatcher { contract_address: imm.token }.transfer(imm.taker, imm.amount);

            // Pay safety deposit to caller
            let eth = self.eth_token.read();
            IERC20Dispatcher { contract_address: eth }.transfer(get_caller_address(), imm.safety_deposit);
        }

        // -------- internals --------

        fn _withdraw(ref self: ContractState, secret: Span<u256>, imm: Immutables) {
            // Validate secret
            if hash_secret(secret) != imm.hashlock { panic!() }

            // Transfer escrowed tokens to maker
            IERC20Dispatcher { contract_address: imm.token }.transfer(imm.maker, imm.amount);

            // Pay safety deposit to caller
            let eth = self.eth_token.read();
            IERC20Dispatcher { contract_address: eth }.transfer(get_caller_address(), imm.safety_deposit);
        }

        // onlyValidImmutables: compare provided with stored (by value)
        fn assert_valid_immutables(self: @ContractState, provided: Immutables) {
            let s = self.immutables.read();
            if !immutables_eq(s, provided) { panic!() }
        }

        fn immutables_eq(a: Immutables, b: Immutables) -> bool {
            if a.maker != b.maker { return false; }
            if a.taker != b.taker { return false; }
            if a.token != b.token { return false; }
            if a.amount != b.amount { return false; }
            if a.safety_deposit != b.safety_deposit { return false; }
            if a.hashlock != b.hashlock { return false; }
            if !timelocks_eq(a.timelocks, b.timelocks) { return false; }
            true
        }

        fn timelocks_eq(a: Timelocks, b: Timelocks) -> bool {
            if a.deployed_at != b.deployed_at { return false; }
            if a.src.finality != b.src.finality { return false; }
            if a.src.withdrawal != b.src.withdrawal { return false; }
            if a.src.cancellation != b.src.cancellation { return false; }
            if a.dst.finality != b.dst.finality { return false; }
            if a.dst.withdrawal != b.dst.withdrawal { return false; }
            if a.dst.public_withdrawal != b.dst.public_withdrawal { return false; }
            true
        }

        fn hash_secret(secret: Span<u256>) -> u256 { hash_data(secret) }
    }
}
