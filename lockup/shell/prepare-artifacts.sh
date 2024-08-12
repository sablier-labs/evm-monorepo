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
  "$artifacts/core" \
  "$artifacts/core/interfaces" \
  "$artifacts/core/libraries" \
  "$artifacts/erc20" \
  "$artifacts/erc721" \
  "$artifacts/periphery" \
  "$artifacts/periphery/interfaces" \
  "$artifacts/periphery/libraries"

################################################
####                 CORE                   ####
################################################

core=./artifacts/core
cp out-optimized/LockupNFTDescriptor.sol/LockupNFTDescriptor.json $core
cp out-optimized/SablierLockupDynamic.sol/SablierLockupDynamic.json $core
cp out-optimized/SablierLockupLinear.sol/SablierLockupLinear.json $core
cp out-optimized/SablierLockupTranched.sol/SablierLockupTranched.json $core

core_interfaces=./artifacts/core/interfaces
cp out-optimized/ILockupNFTDescriptor.sol/ILockupNFTDescriptor.json $core_interfaces
cp out-optimized/ISablierLockupRecipient.sol/ISablierLockupRecipient.json $core_interfaces
cp out-optimized/ISablierLockup.sol/ISablierLockup.json $core_interfaces
cp out-optimized/ISablierLockupDynamic.sol/ISablierLockupDynamic.json $core_interfaces
cp out-optimized/ISablierLockupLinear.sol/ISablierLockupLinear.json $core_interfaces
cp out-optimized/ISablierLockupTranched.sol/ISablierLockupTranched.json $core_interfaces

core_libraries=./artifacts/core/libraries
cp out-optimized/Errors.sol/Errors.json $core_libraries

################################################
####               PERIPHERY                ####
################################################

periphery=./artifacts/periphery
cp out-optimized/SablierBatchLockup.sol/SablierBatchLockup.json $periphery
cp out-optimized/SablierMerkleFactory.sol/SablierMerkleFactory.json $periphery
cp out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json $periphery
cp out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json $periphery
cp out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json $periphery

periphery_interfaces=./artifacts/periphery/interfaces
cp out-optimized/ISablierBatchLockup.sol/ISablierBatchLockup.json $periphery_interfaces
cp out-optimized/ISablierMerkleFactory.sol/ISablierMerkleFactory.json $periphery_interfaces
cp out-optimized/ISablierMerkleInstant.sol/ISablierMerkleInstant.json $periphery_interfaces
cp out-optimized/ISablierMerkleLL.sol/ISablierMerkleLL.json $periphery_interfaces
cp out-optimized/ISablierMerkleLT.sol/ISablierMerkleLT.json $periphery_interfaces

periphery_libraries=./artifacts/periphery/libraries
cp out-optimized/libraries/Errors.sol/Errors.json $periphery_libraries

################################################
####                OTHERS                  ####
################################################

erc20=./artifacts/erc20
cp out-optimized/IERC20.sol/IERC20.json $erc20

erc721=./artifacts/erc721
cp out-optimized/IERC721.sol/IERC721.json $erc721
cp out-optimized/IERC721Metadata.sol/IERC721Metadata.json $erc721

# Format the artifacts with Prettier
bun prettier --write ./artifacts
