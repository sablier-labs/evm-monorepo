#!/usr/bin/env bash

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - jq (https://stedolan.github.io/jq)
# - sd (https://github.com/chmln/sd)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Compile the contracts with Forge
FOUNDRY_PROFILE=optimized forge build

# Retrieve the raw bytecodes, removing the "0x" prefix
batch_lockup=$(cat out-optimized/SablierBatchLockup.sol/SablierBatchLockup.json | jq -r '.bytecode.object' | cut -c 3-)
lockup=$(cat out-optimized/SablierLockup.sol/SablierLockup.json | jq -r '.bytecode.object' | cut -c 3-)
nft_descriptor=$(cat out-optimized/LockupNFTDescriptor.sol/LockupNFTDescriptor.json | jq -r '.bytecode.object' | cut -c 3-)

precompiles_path="precompiles/Precompiles.sol"
if [ ! -f $precompiles_path ]; then
    echo "Precompiles file does not exist"
    exit 1
fi

# Replace the current bytecodes
sd "(BYTECODE_BATCH_LOCKUP =)[^;]+;" "\$1 hex\"$batch_lockup\";" $precompiles_path
sd "(BYTECODE_LOCKUP =)[^;]+;" "\$1 hex\"$lockup\";" $precompiles_path
sd "(BYTECODE_NFT_DESCRIPTOR =)[^;]+;" "\$1 hex\"$nft_descriptor\";" $precompiles_path

# Reformat the code with Forge
forge fmt $precompiles_path
