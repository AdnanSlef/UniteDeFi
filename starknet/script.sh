#!/bin/bash
set -e

export STARKNET_ACCOUNT="/home/node/.accounts/sepolia.json"
export STARKNET_KEYSTORE="/home/node/.keys/starknet.json"
export STARKNET_NETWORK="sepolia"

scarb build

export FILENAME="./target/dev/workspace_HelloStarknet.contract_class.json"
starkli declare --watch $FILENAME
export ADDRESS="$(starkli deploy --watch $(starkli class-hash $FILENAME) $(starkli to-cairo-string notanum) | tee /dev/tty | tail -n1)"
starkli call $ADDRESS get_balance
starkli invoke --watch $ADDRESS increase_balance 3
starkli call $ADDRESS hash_data 1 0x61626364 0