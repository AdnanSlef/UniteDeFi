#!/bin/bash
set -e

export STARKNET_ACCOUNT="/home/node/.accounts/sepolia.json"
export STARKNET_KEYSTORE="/home/node/.keys/starknet.json"
export STARKNET_NETWORK="sepolia"

scarb build

# Test Contract
export CONTRACT="HelloStarknet"
export FILENAME="./target/dev/workspace_$CONTRACT.contract_class.json"
starkli declare --watch $FILENAME
export ADDRESS="$(starkli deploy --watch $(starkli class-hash $FILENAME) $(starkli to-cairo-string notanum) | tee /dev/tty | tail -n1)"
starkli call $ADDRESS get_balance
starkli invoke --watch $ADDRESS increase_balance 3
starkli call $ADDRESS hash_data 1 0x61626364 0

# EscrowSrc Contract
export CONTRACT="EscrowSrc"
export FILENAME="./target/dev/workspace_$CONTRACT.contract_class.json"
starkli declare --watch $FILENAME
export ADDRESS="$(starkli deploy --watch $(starkli class-hash $FILENAME) \
    600 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 0 \
    30  600  1200 \
    20  300  900 \
    0x41a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf \
    0x6ab157cb31c59807c22f70c9f375d1df63e60abb5b0ec5ce964b44854cdbd54 \
    0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080 \
    1000000000000000000 0 \
    10000000000000000   0 \
    0x86bb349304435f6bf67604ee2e499f1a 0x9da131e2c1510c44f68e462af72822b2 \
    | tee /dev/tty | tail -n1)"
# starkli call $ADDRESS hash_secret 1 $(starkli to-cairo-string mysecretpassword) 0

# EscrowDst Contract
export CONTRACT="EscrowDst"
export FILENAME="./target/dev/workspace_$CONTRACT.contract_class.json"
starkli declare --watch $FILENAME
export ADDRESS="$(starkli deploy --watch $(starkli class-hash $FILENAME) \
    600 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 0 \
    30  600  1200 \
    20  300  900 \
    0x41a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf \
    0x6ab157cb31c59807c22f70c9f375d1df63e60abb5b0ec5ce964b44854cdbd54 \
    0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080 \
    1000000000000000000 0 \
    10000000000000000   0 \
    0x86bb349304435f6bf67604ee2e499f1a 0x9da131e2c1510c44f68e462af72822b2 \
    | tee /dev/tty | tail -n1)"
# starkli call $ADDRESS hash_secret 1 $(starkli to-cairo-string mysecretpassword) 0