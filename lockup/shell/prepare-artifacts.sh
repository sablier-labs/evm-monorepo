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
cp out-optimized/SablierV2LockupDynamic.sol/SablierV2LockupDynamic.json $core
cp out-optimized/SablierV2LockupLinear.sol/SablierV2LockupLinear.json $core
cp out-optimized/SablierV2LockupTranched.sol/SablierV2LockupTranched.json $core
cp out-optimized/SablierV2NFTDescriptor.sol/SablierV2NFTDescriptor.json $core

core_interfaces=./artifacts/core/interfaces
cp out-optimized/ISablierLockupRecipient.sol/ISablierLockupRecipient.json $core_interfaces
cp out-optimized/ISablierV2Lockup.sol/ISablierV2Lockup.json $core_interfaces
cp out-optimized/ISablierV2LockupDynamic.sol/ISablierV2LockupDynamic.json $core_interfaces
cp out-optimized/ISablierV2LockupLinear.sol/ISablierV2LockupLinear.json $core_interfaces
cp out-optimized/ISablierV2LockupTranched.sol/ISablierV2LockupTranched.json $core_interfaces
cp out-optimized/ISablierV2NFTDescriptor.sol/ISablierV2NFTDescriptor.json $core_interfaces

core_libraries=./artifacts/core/libraries
cp out-optimized/Errors.sol/Errors.json $core_libraries

################################################
####               PERIPHERY                ####
################################################

periphery=./artifacts/periphery
cp out-optimized/SablierV2BatchLockup.sol/SablierV2BatchLockup.json $periphery
cp out-optimized/SablierV2MerkleLL.sol/SablierV2MerkleLL.json $periphery
cp out-optimized/SablierV2MerkleLockupFactory.sol/SablierV2MerkleLockupFactory.json $periphery
cp out-optimized/SablierV2MerkleLT.sol/SablierV2MerkleLT.json $periphery

periphery_interfaces=./artifacts/periphery/interfaces
cp out-optimized/ISablierV2BatchLockup.sol/ISablierV2BatchLockup.json $periphery_interfaces
cp out-optimized/ISablierV2MerkleLL.sol/ISablierV2MerkleLL.json $periphery_interfaces
cp out-optimized/ISablierV2MerkleLockupFactory.sol/ISablierV2MerkleLockupFactory.json $periphery_interfaces
cp out-optimized/ISablierV2MerkleLT.sol/ISablierV2MerkleLT.json $periphery_interfaces

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
