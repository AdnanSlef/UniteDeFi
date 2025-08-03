# Starknet

I build and deploy the smart contract in the following way from within the devcontainer:

```sh
node@8bddbc77f615:/workspace$ scarb build
node@8bddbc77f615:/workspace$ export STARKNET_ACCOUNT="/home/node/.accounts/sepolia.json"
node@8bddbc77f615:/workspace$ export STARKNET_KEYSTORE="/home/node/.keys/starknet.json"
node@8bddbc77f615:/workspace$ export STARKNET_NETWORK="sepolia"
node@8bddbc77f615:/workspace$ starkli declare --watch ./target/dev/workspace_HelloStarknet.contract_class.json
node@8bddbc77f615:/workspace$ starkli deploy --watch $(starkli class-hash ./target/dev/workspace_HelloStarknet.contract_class.json) $(starkli to-cairo-string notanum)
node@8bddbc77f615:/workspace$ starkli call 0x05e667e04de9df8fe1011e50b8a802113744e8b1e046a19c7b1aa7e893a11ce4 get_balance
node@8bddbc77f615:/workspace$ starkli invoke --watch 0x05e667e04de9df8fe1011e50b8a802113744e8b1e046a19c7b1aa7e893a11ce4 increase_balance 3
```