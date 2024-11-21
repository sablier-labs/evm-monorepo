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
  "$artifacts/interfaces" \
  "$artifacts/libraries" \
  "$artifacts/erc20" \
  "$artifacts/erc721"

################################################
####                LOCKUP                  ####
################################################

lockup=./artifacts/
cp out-optimized/LockupNFTDescriptor.sol/LockupNFTDescriptor.json $lockup
cp out-optimized/SablierLockup.sol/SablierLockup.json $lockup
cp out-optimized/SablierBatchLockup.sol/SablierBatchLockup.json $lockup

lockup_interfaces=./artifacts/interfaces
cp out-optimized/ISablierBatchLockup.sol/ISablierBatchLockup.json $lockup_interfaces
cp out-optimized/ILockupNFTDescriptor.sol/ILockupNFTDescriptor.json $lockup_interfaces
cp out-optimized/ISablierLockupRecipient.sol/ISablierLockupRecipient.json $lockup_interfaces
cp out-optimized/ISablierLockupBase.sol/ISablierLockupBase.json $lockup_interfaces
cp out-optimized/ISablierLockup.sol/ISablierLockup.json $lockup_interfaces

lockup_libraries=./artifacts/libraries
cp out-optimized/Errors.sol/Errors.json $lockup_libraries
cp out-optimized/Helpers.sol/Helpers.json $lockup_libraries
cp out-optimized/VestingMath.sol/VestingMath.json $lockup_libraries


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
