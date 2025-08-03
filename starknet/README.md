# Starknet

I build and deploy the smart contract in the following way from within the devcontainer:

```sh
node@8bddbc77f615:/workspace$ scarb build
node@8bddbc77f615:/workspace$ export STARKNET_ACCOUNT="/home/node/.accounts/sepolia.json"
node@8bddbc77f615:/workspace$ export STARKNET_KEYSTORE="/home/node/.keys/starknet.json"
node@8bddbc77f615:/workspace$ export STARKNET_NETWORK="sepolia"
node@8bddbc77f615:/workspace$ starkli declare --watch ./target/dev/workspace_HelloStarknet.contract_class.json
```