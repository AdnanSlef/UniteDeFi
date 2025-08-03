mod escrow_src {
    use crate::timelock::{
        Timelocks,
        src_withdrawal_start, src_cancellation_start, src_pub_cancellation_start,
    };
    use crate::util::hash_data;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::integer::u256;

    // --- Minimal ERC20 interface/dispatcher ---
    #[starknet::interface]
    trait IERC20<TContractState> {
        fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub struct Immutables {
        pub timelocks: Timelocks,
        pub maker: ContractAddress,
        pub taker: ContractAddress,
        pub token: ContractAddress,     // escrowed asset
        pub amount: u256,
        pub safety_deposit: u256,       // paid to caller on success/cancel
        pub hashlock: u256,          // expected hash(secret)
    }

    #[starknet::contract]
    mod EscrowSrc {
        use super::{
            Immutables, Timelocks, IERC20Dispatcher, IERC20DispatcherTrait,
            ContractAddress, get_caller_address, get_block_timestamp,
            src_withdrawal_start, src_cancellation_start, src_pub_cancellation_start, hash_data
        };
        use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
        use core::integer::u256;

        #[storage]
        struct Storage {
            immutables: Immutables,
            rescue_delay: u64,
            eth_token: ContractAddress,  // ERC-20 used to pay the safety deposit
        }

        // constructor(uint32 rescueDelay) Escrow(rescueDelay)
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

        // withdraw(secret, immutables)
        #[external(v0)]
        fn withdraw(ref self: ContractState, secret: Span<u256>, imm: Immutables) {
            assert_valid_immutables(@self, imm);
            let caller = get_caller_address();
            _withdraw_to(ref self, secret, caller, imm);
        }

        // withdrawTo(secret, target, immutables)
        #[external(v0)]
        fn withdraw_to(ref self: ContractState, secret: Span<u256>, target: ContractAddress, imm: Immutables) {
            assert_valid_immutables(@self, imm);
            _withdraw_to(ref self, secret, target, imm);
        }

        // cancel(immutables)
        #[external(v0)]
        fn cancel(ref self: ContractState, imm: Immutables) {
            assert_valid_immutables(@self, imm);

            let now = get_block_timestamp();
            let t = imm.timelocks;

            // must be in cancellation window
            require(now >= src_cancellation_start(@t));

            // private-cancel window => only taker
            if now < src_pub_cancellation_start(@t) {
                require(get_caller_address() == imm.taker);
            }

            // return escrowed tokens to maker
            IERC20Dispatcher { contract_address: imm.token }.transfer(imm.maker, imm.amount);

            // pay safety deposit to caller
            let eth = self.eth_token.read();
            IERC20Dispatcher { contract_address: eth }.transfer(get_caller_address(), imm.safety_deposit);
        }

        // -------- internals --------

        fn _withdraw_to(ref self: ContractState, secret: Span<u256>, target: ContractAddress, imm: Immutables) {
            // only taker during private withdrawal
            require(get_caller_address() == imm.taker);

            let now = get_block_timestamp();
            let t = imm.timelocks;
            let w_start = src_withdrawal_start(@t);
            let c_start = src_cancellation_start(@t);

            // withdrawal window: [w_start, c_start)
            require(now >= w_start && now < c_start);

            // verify secret and transfer (stubbed: replace with keccak if needed)
            require(hash_secret(secret) == imm.hashlock);

            IERC20Dispatcher { contract_address: imm.token }.transfer(target, imm.amount);

            // pay safety deposit to caller (taker)
            let eth = self.eth_token.read();
            IERC20Dispatcher { contract_address: eth }.transfer(get_caller_address(), imm.safety_deposit);
        }

        // Compare provided immutables to stored (Solidity's onlyValidImmutables).
        fn assert_valid_immutables(self: @ContractState, provided: Immutables) {
            let s = self.immutables.read();
            require(eq_immutables(s, provided));
        }

        // Plain value equality
        fn eq_immutables(a: Immutables, b: Immutables) -> bool {
            a.maker == b.maker
            && a.taker == b.taker
            && a.token == b.token
            && a.amount == b.amount
            && a.safety_deposit == b.safety_deposit
            && a.hashlock == b.hashlock
            && eq_timelocks(a.timelocks, b.timelocks)
        }
        fn eq_timelocks(a: Timelocks, b: Timelocks) -> bool {
            a.deployed_at == b.deployed_at
            && a.src.finality == b.src.finality
            && a.src.withdrawal == b.src.withdrawal
            && a.src.cancellation == b.src.cancellation
            && a.dst.finality == b.dst.finality
            && a.dst.withdrawal == b.dst.withdrawal
            && a.dst.public_withdrawal == b.dst.public_withdrawal
        }

        // simple require; panic without a message
        fn require(ok: bool) {
            if !ok { panic!() }
        }

        // Use keccak to match Solidity's bytes32 hash.
        fn hash_secret(secret: Span<u256>) -> u256 { hash_data(secret) }
    }
}
