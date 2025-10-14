#!/usr/bin/env bash

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - bun (https://bun.sh)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Generate the artifacts with Forge
FOUNDRY_PROFILE=optimized forge build

# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/erc20" \
  "$artifacts/interfaces" \
  "$artifacts/libraries"

cp out-optimized/SablierFactoryMerkleInstant.sol/SablierFactoryMerkleInstant.json $artifacts
cp out-optimized/SablierFactoryMerkleLL.sol/SablierFactoryMerkleLL.json $artifacts
cp out-optimized/SablierFactoryMerkleLT.sol/SablierFactoryMerkleLT.json $artifacts
cp out-optimized/SablierFactoryMerkleVCA.sol/SablierFactoryMerkleVCA.json $artifacts
cp out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json $artifacts
cp out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json $artifacts
cp out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json $artifacts
cp out-optimized/SablierMerkleVCA.sol/SablierMerkleVCA.json $artifacts
cp out-optimized/SignatureHash.sol/SignatureHash.json $artifacts

interfaces=./artifacts/interfaces
cp out-optimized/ISablierFactoryMerkleInstant.sol/ISablierFactoryMerkleInstant.json $interfaces
cp out-optimized/ISablierFactoryMerkleLL.sol/ISablierFactoryMerkleLL.json $interfaces
cp out-optimized/ISablierFactoryMerkleLT.sol/ISablierFactoryMerkleLT.json $interfaces
cp out-optimized/ISablierFactoryMerkleVCA.sol/ISablierFactoryMerkleVCA.json $interfaces
cp out-optimized/ISablierMerkleInstant.sol/ISablierMerkleInstant.json $interfaces
cp out-optimized/ISablierMerkleLL.sol/ISablierMerkleLL.json $interfaces
cp out-optimized/ISablierMerkleLT.sol/ISablierMerkleLT.json $interfaces
cp out-optimized/ISablierMerkleVCA.sol/ISablierMerkleVCA.json $interfaces

libraries=./artifacts/libraries
cp out-optimized/libraries/Errors.sol/Errors.json $libraries

################################################
####                OTHERS                  ####
################################################

erc20=./artifacts/erc20
cp out-optimized/IERC20.sol/IERC20.json $erc20

# Format the artifacts with Prettier
bun prettier --write ./artifacts
