#!/usr/bin/env bash

# Notes:
# - The script must be run from the repo's root directory

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - pnpm (https://pnpm.io)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts
mkdir $artifacts

# Generate the artifacts with Forge
FOUNDRY_PROFILE=optimized forge build

# Copy the production artifacts
cp optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json $artifacts
cp optimized-out/SablierV2LockupDynamic.sol/SablierV2LockupDynamic.json $artifacts
cp optimized-out/SablierV2LockupLinear.sol/SablierV2LockupLinear.json $artifacts

interfaces=./artifacts/interfaces
mkdir $interfaces
cp optimized-out/ISablierV2Base.sol/ISablierV2Base.json $interfaces
cp optimized-out/ISablierV2Comptroller.sol/ISablierV2Comptroller.json $interfaces
cp optimized-out/ISablierV2Lockup.sol/ISablierV2Lockup.json $interfaces
cp optimized-out/ISablierV2LockupDynamic.sol/ISablierV2LockupDynamic.json $interfaces
cp optimized-out/ISablierV2LockupLinear.sol/ISablierV2LockupLinear.json $interfaces

erc20=./artifacts/interfaces/erc20
mkdir $erc20
cp optimized-out/IERC20.sol/IERC20.json $erc20

erc721=./artifacts/interfaces/erc721
mkdir $erc721
cp optimized-out/IERC721.sol/IERC721.json $erc721
cp optimized-out/IERC721Metadata.sol/IERC721Metadata.json $erc721

hooks=./artifacts/interfaces/hooks
mkdir $hooks
cp optimized-out/ISablierV2LockupRecipient.sol/ISablierV2LockupRecipient.json $hooks
cp optimized-out/ISablierV2LockupSender.sol/ISablierV2LockupSender.json $hooks

libraries=./artifacts/libraries
mkdir $libraries
cp optimized-out/Errors.sol/Errors.json $libraries

# Format the artifacts with Prettier
pnpm prettier --write ./artifacts
